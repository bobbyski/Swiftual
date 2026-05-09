import Foundation

public struct Switch: CanvasRenderable, Equatable, Sendable {
    public var title: String
    public var frame: Rect
    public var isOn: Bool
    public var isFocused: Bool
    public var isEnabled: Bool
    public var offStyle: TerminalStyle
    public var onStyle: TerminalStyle
    public var focusedOffStyle: TerminalStyle
    public var focusedOnStyle: TerminalStyle
    public var disabledStyle: TerminalStyle

    public init(
        _ title: String,
        frame: Rect,
        isOn: Bool = false,
        isFocused: Bool = false,
        isEnabled: Bool = true,
        offStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .brightBlack),
        onStyle: TerminalStyle = TerminalStyle(foreground: .black, background: .green, bold: true),
        focusedOffStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true),
        focusedOnStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .green, bold: true),
        disabledStyle: TerminalStyle = TerminalStyle(foreground: .white, background: .brightBlack)
    ) {
        self.title = title
        self.frame = frame
        self.isOn = isOn
        self.isFocused = isFocused
        self.isEnabled = isEnabled
        self.offStyle = offStyle
        self.onStyle = onStyle
        self.focusedOffStyle = focusedOffStyle
        self.focusedOnStyle = focusedOnStyle
        self.disabledStyle = disabledStyle
    }

    public mutating func handle(_ event: InputEvent) -> SwitchCommand {
        guard isEnabled else { return .none }

        switch event {
        case .key(.enter), .key(.character(" ")):
            guard isFocused else { return .none }
            isOn.toggle()
            return .changed(isOn)
        case .mouse(let mouse):
            guard mouse.pressed, mouse.button == .left, frame.contains(mouse.location) else {
                return .none
            }
            isFocused = true
            isOn.toggle()
            return .changed(isOn)
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
            currentStyle = isOn ? focusedOnStyle : focusedOffStyle
        } else if isOn {
            currentStyle = onStyle
        } else {
            currentStyle = offStyle
        }

        canvas.fill(rect: frame, style: currentStyle)
        let marker = isOn ? "<ON>" : "<OFF>"
        let text = "\(marker) \(title)"
        canvas.drawText(String(text.prefix(frame.width)), at: Point(x: frame.x, y: frame.y), style: currentStyle)
    }
}

public enum SwitchCommand: Equatable, Sendable {
    case none
    case changed(Bool)
}
