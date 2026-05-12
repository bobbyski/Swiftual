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
    public var dim: Bool
    public var italic: Bool
    public var underline: Bool
    public var strikethrough: Bool
    public var inverse: Bool
    public var blink: Bool

    public init(
        foreground: TerminalColor? = nil,
        background: TerminalColor? = nil,
        bold: Bool = false,
        dim: Bool = false,
        italic: Bool = false,
        underline: Bool = false,
        strikethrough: Bool = false,
        inverse: Bool = false,
        blink: Bool = false
    ) {
        self.foreground = foreground
        self.background = background
        self.bold = bold
        self.dim = dim
        self.italic = italic
        self.underline = underline
        self.strikethrough = strikethrough
        self.inverse = inverse
        self.blink = blink
    }

    public static let plain = TerminalStyle()
}

extension TerminalStyle {
    func ansiPrefix() -> String {
        var codes: [String] = []
        if bold { codes.append("1") }
        if dim { codes.append("2") }
        if italic { codes.append("3") }
        if underline { codes.append("4") }
        if blink { codes.append("5") }
        if inverse { codes.append("7") }
        if strikethrough { codes.append("9") }
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
