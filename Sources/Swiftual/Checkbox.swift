import Foundation

public struct Checkbox: CanvasRenderable, Equatable, Sendable {
    public var title: String
    public var frame: Rect
    public var isChecked: Bool
    public var isFocused: Bool
    public var isEnabled: Bool
    public var style: TerminalStyle
    public var focusedStyle: TerminalStyle
    public var disabledStyle: TerminalStyle

    public init(
        _ title: String,
        frame: Rect,
        isChecked: Bool = false,
        isFocused: Bool = false,
        isEnabled: Bool = true,
        style: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .brightBlack),
        focusedStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true),
        disabledStyle: TerminalStyle = TerminalStyle(foreground: .white, background: .brightBlack)
    ) {
        self.title = title
        self.frame = frame
        self.isChecked = isChecked
        self.isFocused = isFocused
        self.isEnabled = isEnabled
        self.style = style
        self.focusedStyle = focusedStyle
        self.disabledStyle = disabledStyle
    }

    public mutating func handle(_ event: InputEvent) -> CheckboxCommand {
        guard isEnabled else { return .none }

        switch event {
        case .key(.enter), .key(.character(" ")):
            guard isFocused else { return .none }
            isChecked.toggle()
            return .changed(isChecked)
        case .mouse(let mouse):
            guard mouse.pressed, mouse.button == .left, frame.contains(mouse.location) else {
                return .none
            }
            isFocused = true
            isChecked.toggle()
            return .changed(isChecked)
        default:
            return .none
        }
    }

    public func render(in canvas: inout Canvas) {
        guard frame.width > 0, frame.height > 0 else { return }

        let currentStyle: TerminalStyle
        if !isEnabled {
            currentStyle = disabledStyle
        } else if isFocused {
            currentStyle = focusedStyle
        } else {
            currentStyle = style
        }

        canvas.fill(rect: frame, style: currentStyle)
        let marker = isChecked ? "[x]" : "[ ]"
        let text = "\(marker) \(title)"
        canvas.drawText(String(text.prefix(frame.width)), at: Point(x: frame.x, y: frame.y), style: currentStyle)
    }
}

public enum CheckboxCommand: Equatable, Sendable {
    case none
    case changed(Bool)
}
