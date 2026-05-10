import Darwin
import Foundation

public enum TerminalKind: String, CaseIterable, Sendable {
    case ansi
    case vt100
}

public enum TerminalBackendSelection: Equatable, Sendable {
    case automatic
    case manual(TerminalKind)
}

public protocol TerminalDevice: AnyObject, Sendable {
    func readInput(maxBytes: Int) throws -> [UInt8]
    func writeOutput(_ output: String) throws
    func size() -> TerminalSize
    func enableRawMode() throws
    func restoreMode()
}

public protocol TerminalBackend: Sendable {
    var kind: TerminalKind { get }
    func enterApplicationMode(device: TerminalDevice) throws
    func exitApplicationMode(device: TerminalDevice) throws
    func render(_ canvas: Canvas, device: TerminalDevice) throws
    func decodeInput(_ bytes: [UInt8]) -> [InputEvent]
}

public enum TerminalDetector {
    public static func detect(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        selection: TerminalBackendSelection = .automatic
    ) -> TerminalBackend {
        switch selection {
        case .manual(.ansi):
            return ANSITerminalBackend(kind: .ansi)
        case .manual(.vt100):
            return ANSITerminalBackend(kind: .vt100)
        case .automatic:
            let term = environment["TERM"]?.lowercased() ?? ""
            if term.contains("vt100") {
                return ANSITerminalBackend(kind: .vt100)
            }
            return ANSITerminalBackend(kind: .ansi)
        }
    }
}

public final class FileDescriptorTerminalDevice: TerminalDevice, @unchecked Sendable {
    private let input: Int32
    private let output: Int32
    private var originalTermios: termios?

    public init(input: Int32 = STDIN_FILENO, output: Int32 = STDOUT_FILENO) {
        self.input = input
        self.output = output
    }

    public func readInput(maxBytes: Int = 64) throws -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: max(1, maxBytes))
        let count = Darwin.read(input, &buffer, buffer.count)
        if count < 0 {
            throw TerminalError.readFailed(errno)
        }

        var bytes = Array(buffer.prefix(count))
        while bytes.count < maxBytes, hasPendingInput() {
            var next: UInt8 = 0
            let nextCount = Darwin.read(input, &next, 1)
            if nextCount <= 0 {
                break
            }
            bytes.append(next)
        }
        return bytes
    }

    public func writeOutput(_ output: String) throws {
        let bytes = Array(output.utf8)
        var written = 0
        while written < bytes.count {
            let count = bytes.withUnsafeBytes { pointer in
                Darwin.write(self.output, pointer.baseAddress!.advanced(by: written), bytes.count - written)
            }
            if count < 0 {
                throw TerminalError.writeFailed(errno)
            }
            written += count
        }
    }

    public func size() -> TerminalSize {
        var window = winsize()
        if ioctl(output, TIOCGWINSZ, &window) == 0, window.ws_col > 0, window.ws_row > 0 {
            return TerminalSize(columns: Int(window.ws_col), rows: Int(window.ws_row))
        }
        return .fallback
    }

    public func enableRawMode() throws {
        var current = termios()
        guard tcgetattr(input, &current) == 0 else {
            throw TerminalError.rawModeFailed(errno)
        }
        originalTermios = current

        current.c_lflag &= ~(UInt(ECHO | ICANON | IEXTEN | ISIG))
        current.c_iflag &= ~(UInt(IXON | ICRNL | BRKINT | INPCK | ISTRIP))
        current.c_oflag &= ~(UInt(OPOST))
        current.c_cflag |= UInt(CS8)
        current.c_cc.16 = 0
        current.c_cc.17 = 1

        guard tcsetattr(input, TCSAFLUSH, &current) == 0 else {
            throw TerminalError.rawModeFailed(errno)
        }
    }

    public func restoreMode() {
        guard var originalTermios else { return }
        tcsetattr(input, TCSAFLUSH, &originalTermios)
        self.originalTermios = nil
    }

    private func hasPendingInput() -> Bool {
        var readSet = fd_set()
        fdZero(&readSet)
        fdSet(input, set: &readSet)
        var timeout = timeval(tv_sec: 0, tv_usec: 1_000)
        return select(input + 1, &readSet, nil, nil, &timeout) > 0
    }
}

private func fdZero(_ set: inout fd_set) {
    withUnsafeMutablePointer(to: &set) { pointer in
        pointer.withMemoryRebound(to: Int32.self, capacity: MemoryLayout<fd_set>.size / MemoryLayout<Int32>.size) { words in
            for index in 0..<(MemoryLayout<fd_set>.size / MemoryLayout<Int32>.size) {
                words[index] = 0
            }
        }
    }
}

private func fdSet(_ fd: Int32, set: inout fd_set) {
    let intBits = Int32(MemoryLayout<Int32>.size * 8)
    let index = Int(fd / intBits)
    let bit = fd % intBits
    withUnsafeMutablePointer(to: &set) { pointer in
        pointer.withMemoryRebound(to: Int32.self, capacity: MemoryLayout<fd_set>.size / MemoryLayout<Int32>.size) { words in
            words[index] |= 1 << bit
        }
    }
}

public enum TerminalError: Error, Equatable {
    case readFailed(Int32)
    case writeFailed(Int32)
    case rawModeFailed(Int32)
}

public struct ANSITerminalBackend: TerminalBackend {
    public let kind: TerminalKind

    public init(kind: TerminalKind = .ansi) {
        self.kind = kind
    }

    public func enterApplicationMode(device: TerminalDevice) throws {
        try device.writeOutput("\u{001B}[?1049h\u{001B}[?25l\u{001B}[?1000h\u{001B}[?1002h\u{001B}[?1006h\u{001B}[2J\u{001B}[H")
    }

    public func exitApplicationMode(device: TerminalDevice) throws {
        try device.writeOutput("\u{001B}[?1006l\u{001B}[?1002l\u{001B}[?1000l\u{001B}[?25h\u{001B}[0m\u{001B}[?1049l")
    }

    public func render(_ canvas: Canvas, device: TerminalDevice) throws {
        var output = "\u{001B}[?7l\u{001B}[2J"
        var currentStyle = TerminalStyle.plain

        let rows = canvas.rows()
        for rowIndex in rows.indices {
            let row = rows[rowIndex]
            output += "\u{001B}[\(rowIndex + 1);1H"
            for cell in row {
                if cell.style != currentStyle {
                    output += "\u{001B}[0m"
                    output += cell.style.ansiPrefix()
                    currentStyle = cell.style
                }
                output.append(cell.character)
            }
            output += "\u{001B}[0m"
            currentStyle = .plain
        }
        output += "\u{001B}[?7h"

        try device.writeOutput(output)
    }

    public func decodeInput(_ bytes: [UInt8]) -> [InputEvent] {
        InputParser().parse(bytes)
    }
}
