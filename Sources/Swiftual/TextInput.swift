import Foundation

public struct TextInput: CanvasRenderable, Equatable, Sendable {
    public var frame: Rect
    public var text: String
    public var placeholder: String
    public var cursorIndex: Int
    public var isFocused: Bool
    public var isEnabled: Bool
    public var style: TerminalStyle
    public var focusedStyle: TerminalStyle
    public var placeholderStyle: TerminalStyle
    public var cursorStyle: TerminalStyle
    public var cursorBlinkInterval: TimeInterval

    public init(
        text: String = "",
        placeholder: String = "",
        frame: Rect,
        cursorIndex: Int? = nil,
        isFocused: Bool = false,
        isEnabled: Bool = true,
        style: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        focusedStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue),
        placeholderStyle: TerminalStyle = TerminalStyle(foreground: .white, background: .black),
        cursorStyle: TerminalStyle = TerminalStyle(foreground: .black, background: .brightWhite, bold: true),
        cursorBlinkInterval: TimeInterval = 0.5
    ) {
        self.frame = frame
        self.text = text
        self.placeholder = placeholder
        self.cursorIndex = min(max(0, cursorIndex ?? text.count), text.count)
        self.isFocused = isFocused
        self.isEnabled = isEnabled
        self.style = style
        self.focusedStyle = focusedStyle
        self.placeholderStyle = placeholderStyle
        self.cursorStyle = cursorStyle
        self.cursorBlinkInterval = cursorBlinkInterval
    }

    public mutating func handle(_ event: InputEvent) -> TextInputCommand {
        guard isEnabled else { return .none }

        switch event {
        case .key(.character(let character)):
            guard isFocused else { return .none }
            insert(character)
            return .changed(text)
        case .key(.backspace):
            guard isFocused, cursorIndex > 0 else { return .none }
            let index = text.index(text.startIndex, offsetBy: cursorIndex - 1)
            text.remove(at: index)
            cursorIndex -= 1
            return .changed(text)
        case .key(.left):
            guard isFocused else { return .none }
            cursorIndex = max(0, cursorIndex - 1)
            return .cursorMoved(cursorIndex)
        case .key(.right):
            guard isFocused else { return .none }
            cursorIndex = min(text.count, cursorIndex + 1)
            return .cursorMoved(cursorIndex)
        case .key(.enter):
            guard isFocused else { return .none }
            return .submitted(text)
        case .mouse(let mouse):
            guard mouse.pressed, mouse.button == .left, frame.contains(mouse.location) else {
                return .none
            }
            isFocused = true
            cursorIndex = min(text.count, max(0, mouse.location.x - frame.x - 1))
            return .focused
        default:
            return .none
        }
    }

    public func render(in canvas: inout Canvas) {
        render(in: &canvas, now: Date())
    }

    public func render(in canvas: inout Canvas, now: Date) {
        guard frame.width > 0, frame.height > 0 else { return }

        let currentStyle = isFocused ? focusedStyle : style
        canvas.fill(rect: frame, style: currentStyle)

        let contentWidth = max(0, frame.width - 2)
        guard contentWidth > 0 else { return }

        let startIndex = visibleStartIndex(contentWidth: contentWidth)
        let displayText: String
        let displayStyle: TerminalStyle
        if text.isEmpty && !isFocused {
            displayText = String(placeholder.prefix(contentWidth))
            displayStyle = placeholderStyle
        } else {
            displayText = visibleText(startIndex: startIndex, width: contentWidth)
            displayStyle = currentStyle
        }

        canvas.drawText(displayText, at: Point(x: frame.x + 1, y: frame.y), style: displayStyle)

        if isFocused {
            let displayCursorIndex = cursorIndex
            let cursorOffset = min(max(0, displayCursorIndex - startIndex), contentWidth - 1)
            let cursorX = frame.x + 1 + cursorOffset
            let cursorCharacter = displayCursorIndex < text.count
                ? text[text.index(text.startIndex, offsetBy: displayCursorIndex)]
                : " "
            let renderedCursorStyle = cursorShouldHighlight(now: now)
                ? terminalBlinkRemoved(from: cursorStyle)
                : currentStyle
            canvas[cursorX, frame.y] = Cell(cursorCharacter, style: renderedCursorStyle)
        }
    }

    private mutating func insert(_ character: Character) {
        let index = text.index(text.startIndex, offsetBy: cursorIndex)
        text.insert(character, at: index)
        cursorIndex += 1
    }

    private func visibleStartIndex(contentWidth: Int) -> Int {
        guard contentWidth > 0, isFocused else { return 0 }
        let desiredCursor = cursorIndex == text.count ? cursorIndex + 1 : cursorIndex
        if desiredCursor <= contentWidth {
            return 0
        }
        return min(max(0, text.count - contentWidth + 1), desiredCursor - contentWidth)
    }

    private func visibleText(startIndex: Int, width: Int) -> String {
        guard width > 0 else { return "" }
        let start = text.index(text.startIndex, offsetBy: min(startIndex, text.count))
        let suffix = text[start...]
        return String(suffix.prefix(width))
    }

    private func cursorShouldHighlight(now: Date) -> Bool {
        guard cursorStyle.blink, cursorBlinkInterval > 0 else {
            return true
        }
        let phase = Int((now.timeIntervalSinceReferenceDate / cursorBlinkInterval).rounded(.down))
        return phase.isMultiple(of: 2)
    }

    private func terminalBlinkRemoved(from style: TerminalStyle) -> TerminalStyle {
        var style = style
        style.blink = false
        return style
    }

}

public enum TextInputCommand: Equatable, Sendable {
    case none
    case focused
    case changed(String)
    case cursorMoved(Int)
    case submitted(String)
}
