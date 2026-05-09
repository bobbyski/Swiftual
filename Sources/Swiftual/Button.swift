import Foundation

public struct Button: Equatable, Sendable {
    public var title: String
    public var frame: Rect
    public var isFocused: Bool
    public var isEnabled: Bool
    public var style: TerminalStyle
    public var focusedStyle: TerminalStyle
    public var disabledStyle: TerminalStyle
    public var action: @Sendable () -> Void

    public init(
        _ title: String,
        frame: Rect,
        isFocused: Bool = false,
        isEnabled: Bool = true,
        style: TerminalStyle = Button.defaultStyle,
        focusedStyle: TerminalStyle = Button.defaultFocusedStyle,
        disabledStyle: TerminalStyle = Button.defaultDisabledStyle,
        action: @escaping @Sendable () -> Void = {}
    ) {
        self.title = title
        self.frame = frame
        self.isFocused = isFocused
        self.isEnabled = isEnabled
        self.style = style
        self.focusedStyle = focusedStyle
        self.disabledStyle = disabledStyle
        self.action = action
    }

    public static let defaultStyle = TerminalStyle(foreground: .black, background: .brightWhite)
    public static let defaultFocusedStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true)
    public static let defaultDisabledStyle = TerminalStyle(foreground: .white, background: .brightBlack)

    public static func == (lhs: Button, rhs: Button) -> Bool {
        lhs.title == rhs.title &&
            lhs.frame == rhs.frame &&
            lhs.isFocused == rhs.isFocused &&
            lhs.isEnabled == rhs.isEnabled &&
            lhs.style == rhs.style &&
            lhs.focusedStyle == rhs.focusedStyle &&
            lhs.disabledStyle == rhs.disabledStyle
    }

    public mutating func handle(_ event: InputEvent) -> ButtonCommand {
        guard isEnabled else { return .none }

        switch event {
        case .key(.enter), .key(.character(" ")):
            guard isFocused else { return .none }
            action()
            return .activated(title)
        case .mouse(let mouse):
            guard mouse.pressed, mouse.button == .left, frame.contains(mouse.location) else {
                return .none
            }
            action()
            return .activated(title)
        default:
            return .none
        }
    }

    public func render(in canvas: inout Canvas) {
        let style: TerminalStyle
        if !isEnabled {
            style = disabledStyle
        } else if isFocused {
            style = focusedStyle
        } else {
            style = self.style
        }

        canvas.fill(rect: frame, style: style)
        let label = " \(title) "
        let labelX = frame.x + max(0, (frame.width - label.count) / 2)
        let labelY = frame.y + max(0, frame.height / 2)
        canvas.drawText(String(label.prefix(frame.width)), at: Point(x: labelX, y: labelY), style: style)
    }
}

public enum ButtonCommand: Equatable, Sendable {
    case none
    case activated(String)
}
