import Foundation

public struct SelectOption: Equatable, Sendable {
    public var title: String
    public var isEnabled: Bool

    public init(_ title: String, isEnabled: Bool = true) {
        self.title = title
        self.isEnabled = isEnabled
    }
}

public struct Select: CanvasRenderable, Equatable, Sendable {
    public var frame: Rect
    public var options: [SelectOption]
    public var selectedIndex: Int
    public var highlightedIndex: Int
    public var isOpen: Bool
    public var isFocused: Bool
    public var isEnabled: Bool
    public var style: TerminalStyle
    public var focusedStyle: TerminalStyle
    public var openStyle: TerminalStyle
    public var optionStyle: TerminalStyle
    public var highlightedStyle: TerminalStyle
    public var disabledStyle: TerminalStyle

    public init(
        frame: Rect,
        options: [SelectOption],
        selectedIndex: Int = 0,
        isOpen: Bool = false,
        isFocused: Bool = false,
        isEnabled: Bool = true,
        style: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .brightBlack),
        focusedStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true),
        openStyle: TerminalStyle = TerminalStyle(foreground: .black, background: .brightWhite, bold: true),
        optionStyle: TerminalStyle = TerminalStyle(foreground: .black, background: .brightWhite),
        highlightedStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true),
        disabledStyle: TerminalStyle = TerminalStyle(foreground: .white, background: .brightBlack)
    ) {
        self.frame = frame
        self.options = options
        let fallbackIndex = options.indices.first ?? 0
        let clampedSelected = options.indices.contains(selectedIndex) ? selectedIndex : fallbackIndex
        self.selectedIndex = clampedSelected
        self.highlightedIndex = clampedSelected
        self.isOpen = isOpen
        self.isFocused = isFocused
        self.isEnabled = isEnabled
        self.style = style
        self.focusedStyle = focusedStyle
        self.openStyle = openStyle
        self.optionStyle = optionStyle
        self.highlightedStyle = highlightedStyle
        self.disabledStyle = disabledStyle
    }

    public var selectedOption: SelectOption? {
        guard options.indices.contains(selectedIndex) else { return nil }
        return options[selectedIndex]
    }

    public mutating func handle(_ event: InputEvent) -> SelectCommand {
        guard isEnabled, !options.isEmpty else { return .none }

        switch event {
        case .key(.enter), .key(.character(" ")):
            guard isFocused else { return .none }
            if isOpen {
                return selectHighlighted()
            }
            isOpen = true
            highlightedIndex = selectedIndex
            return .opened
        case .key(.escape):
            guard isOpen else { return .none }
            isOpen = false
            highlightedIndex = selectedIndex
            return .closed
        case .key(.down):
            guard isFocused else { return .none }
            if !isOpen {
                isOpen = true
                highlightedIndex = selectedIndex
                return .opened
            }
            moveHighlight(delta: 1)
            return .highlighted(highlightedIndex)
        case .key(.up):
            guard isFocused else { return .none }
            if !isOpen {
                isOpen = true
                highlightedIndex = selectedIndex
                return .opened
            }
            moveHighlight(delta: -1)
            return .highlighted(highlightedIndex)
        case .mouse(let mouse):
            guard mouse.pressed, mouse.button == .left else { return .none }
            if frame.contains(mouse.location) {
                isFocused = true
                if isOpen {
                    return selectHighlighted()
                }
                isOpen = true
                highlightedIndex = selectedIndex
                return .opened
            }
            if isOpen, let optionIndex = optionIndex(at: mouse.location) {
                highlightedIndex = optionIndex
                return selectHighlighted()
            }
            if isOpen {
                isOpen = false
                return .closed
            }
            return .none
        default:
            return .none
        }
    }

    public func render(in canvas: inout Canvas) {
        guard frame.width > 0, frame.height > 0 else { return }

        let controlStyle: TerminalStyle
        if !isEnabled {
            controlStyle = disabledStyle
        } else if isOpen {
            controlStyle = openStyle
        } else if isFocused {
            controlStyle = focusedStyle
        } else {
            controlStyle = style
        }

        canvas.fill(rect: frame, style: controlStyle)
        let title = selectedOption?.title ?? ""
        let closedText = " \(title) v"
        canvas.drawText(String(closedText.prefix(frame.width)), at: Point(x: frame.x, y: frame.y), style: controlStyle)

        guard isOpen else { return }

        let popupHeight = min(options.count, max(0, canvas.size.rows - frame.y - frame.height))
        guard popupHeight > 0 else { return }

        for offset in 0..<popupHeight {
            let optionIndex = offset
            guard options.indices.contains(optionIndex) else { return }
            let option = options[optionIndex]
            let optionFrame = Rect(x: frame.x, y: frame.y + frame.height + offset, width: frame.width, height: 1)
            let currentStyle = optionIndex == highlightedIndex ? highlightedStyle : (option.isEnabled ? optionStyle : disabledStyle)
            canvas.fill(rect: optionFrame, style: currentStyle)
            canvas.drawText(String((" " + option.title).prefix(frame.width)), at: Point(x: optionFrame.x, y: optionFrame.y), style: currentStyle)
        }
    }

    private mutating func selectHighlighted() -> SelectCommand {
        guard options.indices.contains(highlightedIndex), options[highlightedIndex].isEnabled else {
            return .none
        }
        selectedIndex = highlightedIndex
        isOpen = false
        return .changed(selectedIndex, options[selectedIndex].title)
    }

    private mutating func moveHighlight(delta: Int) {
        guard !options.isEmpty else { return }

        var next = highlightedIndex
        for _ in options.indices {
            next = (next + delta + options.count) % options.count
            if options[next].isEnabled {
                highlightedIndex = next
                return
            }
        }
    }

    private func optionIndex(at point: Point) -> Int? {
        let popupY = frame.y + frame.height
        guard point.x >= frame.x, point.x < frame.x + frame.width, point.y >= popupY else {
            return nil
        }
        let index = point.y - popupY
        return options.indices.contains(index) ? index : nil
    }
}

public enum SelectCommand: Equatable, Sendable {
    case none
    case opened
    case closed
    case highlighted(Int)
    case changed(Int, String)
}
