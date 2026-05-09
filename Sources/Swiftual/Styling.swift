import Foundation

public enum TerminalColor: Equatable, Sendable {
    case ansi(Int)
    case rgb(UInt8, UInt8, UInt8)

    public static let black = TerminalColor.ansi(0)
    public static let red = TerminalColor.ansi(1)
    public static let green = TerminalColor.ansi(2)
    public static let yellow = TerminalColor.ansi(3)
    public static let blue = TerminalColor.ansi(4)
    public static let magenta = TerminalColor.ansi(5)
    public static let cyan = TerminalColor.ansi(6)
    public static let white = TerminalColor.ansi(7)
    public static let brightBlack = TerminalColor.ansi(8)
    public static let brightWhite = TerminalColor.ansi(15)
}

public struct TerminalStyle: Equatable, Sendable {
    public var foreground: TerminalColor?
    public var background: TerminalColor?
    public var bold: Bool
    public var inverse: Bool

    public init(
        foreground: TerminalColor? = nil,
        background: TerminalColor? = nil,
        bold: Bool = false,
        inverse: Bool = false
    ) {
        self.foreground = foreground
        self.background = background
        self.bold = bold
        self.inverse = inverse
    }

    public static let plain = TerminalStyle()
}

extension TerminalStyle {
    func ansiPrefix() -> String {
        var codes: [String] = []
        if bold { codes.append("1") }
        if inverse { codes.append("7") }
        if let foreground {
            codes.append(contentsOf: foreground.ansiCodes(background: false))
        }
        if let background {
            codes.append(contentsOf: background.ansiCodes(background: true))
        }
        return codes.isEmpty ? "" : "\u{001B}[\(codes.joined(separator: ";"))m"
    }
}

extension TerminalColor {
    func ansiCodes(background: Bool) -> [String] {
        switch self {
        case .ansi(let index):
            if index >= 0 && index <= 7 {
                return [String((background ? 40 : 30) + index)]
            }
            if index >= 8 && index <= 15 {
                return [String((background ? 100 : 90) + index - 8)]
            }
            return [background ? "48" : "38", "5", String(index)]
        case .rgb(let red, let green, let blue):
            return [background ? "48" : "38", "2", String(red), String(green), String(blue)]
        }
    }
}
