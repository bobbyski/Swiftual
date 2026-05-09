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
        return Array(buffer.prefix(count))
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
        current.c_cc.16 = 1
        current.c_cc.17 = 0

        guard tcsetattr(input, TCSAFLUSH, &current) == 0 else {
            throw TerminalError.rawModeFailed(errno)
        }
    }

    public func restoreMode() {
        guard var originalTermios else { return }
        tcsetattr(input, TCSAFLUSH, &originalTermios)
        self.originalTermios = nil
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
        try device.writeOutput("\u{001B}[?1049h\u{001B}[?25l\u{001B}[?1000h\u{001B}[?1006h\u{001B}[2J\u{001B}[H")
    }

    public func exitApplicationMode(device: TerminalDevice) throws {
        try device.writeOutput("\u{001B}[?1006l\u{001B}[?1000l\u{001B}[?25h\u{001B}[0m\u{001B}[?1049l")
    }

    public func render(_ canvas: Canvas, device: TerminalDevice) throws {
        var output = "\u{001B}[H"
        var currentStyle = TerminalStyle.plain

        for row in canvas.rows() {
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
            output += "\r\n"
        }

        try device.writeOutput(output)
    }

    public func decodeInput(_ bytes: [UInt8]) -> [InputEvent] {
        InputParser().parse(bytes)
    }
}
