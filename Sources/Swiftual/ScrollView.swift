import Foundation

public struct ScrollView: CanvasRenderable, Equatable, Sendable {
    public var frame: Rect
    public var contentHeight: Int
    public var scrollOffset: Int
    public var isFocused: Bool
    public var fillStyle: TerminalStyle
    public var scrollbarStyle: TerminalStyle
    public var thumbStyle: TerminalStyle
    public var content: [String]
    public var contentStyle: TerminalStyle
    public var scrollbarWidth: Int

    public init(
        frame: Rect,
        content: [String],
        scrollOffset: Int = 0,
        isFocused: Bool = false,
        fillStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        scrollbarStyle: TerminalStyle = TerminalStyle(foreground: .white, background: .brightBlack),
        thumbStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true),
        contentStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        scrollbarWidth: Int = 2
    ) {
        self.frame = frame
        self.content = content
        self.contentHeight = content.count
        self.scrollOffset = min(max(0, scrollOffset), max(0, content.count - frame.height))
        self.isFocused = isFocused
        self.fillStyle = fillStyle
        self.scrollbarStyle = scrollbarStyle
        self.thumbStyle = thumbStyle
        self.contentStyle = contentStyle
        self.scrollbarWidth = max(1, scrollbarWidth)
    }

    public mutating func handle(_ event: InputEvent) -> ScrollViewCommand {
        switch event {
        case .key(.down):
            guard isFocused else { return .none }
            return scroll(by: 1)
        case .key(.up):
            guard isFocused else { return .none }
            return scroll(by: -1)
        case .mouse(let mouse):
            if mouse.button == .left,
               mouse.pressed,
               isScrollbarLocation(mouse.location) {
                isFocused = true
                return scroll(toThumbLocation: mouse.location)
            }
            guard frame.contains(mouse.location) else { return .none }
            switch mouse.button {
            case .scrollDown:
                return scroll(by: 1)
            case .scrollUp:
                return scroll(by: -1)
            case .left:
                if mouse.pressed {
                    isFocused = true
                    return .focused
                }
                return .none
            default:
                return .none
            }
        default:
            return .none
        }
    }

    public func render(in canvas: inout Canvas) {
        guard frame.width > 0, frame.height > 0 else { return }
        canvas.fill(rect: frame, style: fillStyle)

        let contentWidth = max(0, frame.width - effectiveScrollbarWidth)
        for rowOffset in 0..<frame.height {
            let contentIndex = scrollOffset + rowOffset
            guard content.indices.contains(contentIndex) else { break }
            let text = String(content[contentIndex].prefix(contentWidth))
            canvas.drawText(text, at: Point(x: frame.x, y: frame.y + rowOffset), style: contentStyle)
        }

        renderScrollbar(in: &canvas)
    }

    private var effectiveScrollbarWidth: Int {
        contentHeight > frame.height ? min(max(1, scrollbarWidth), frame.width) : 0
    }

    private mutating func scroll(by delta: Int) -> ScrollViewCommand {
        let old = scrollOffset
        scrollOffset = min(max(0, scrollOffset + delta), maxScrollOffset)
        return old == scrollOffset ? .none : .scrolled(scrollOffset)
    }

    private var maxScrollOffset: Int {
        max(0, contentHeight - frame.height)
    }

    private func isScrollbarLocation(_ location: Point) -> Bool {
        let width = effectiveScrollbarWidth
        guard width > 0 else { return false }
        return location.x >= frame.x + frame.width - width && location.x < frame.x + frame.width
    }

    private mutating func scroll(toThumbLocation location: Point) -> ScrollViewCommand {
        guard contentHeight > frame.height, frame.height > 0 else { return .none }
        let old = scrollOffset
        let relativeY = min(max(0, location.y - frame.y), frame.height - 1)
        let thumbHeight = max(1, frame.height * frame.height / max(1, contentHeight))
        let travel = max(1, frame.height - thumbHeight)
        scrollOffset = min(maxScrollOffset, max(0, relativeY * maxScrollOffset / travel))
        return old == scrollOffset ? .focused : .scrolled(scrollOffset)
    }

    private func renderScrollbar(in canvas: inout Canvas) {
        guard contentHeight > frame.height, frame.width > 0 else { return }
        let width = effectiveScrollbarWidth
        let x = frame.x + frame.width - width
        let track = Rect(x: x, y: frame.y, width: width, height: frame.height)
        canvas.fill(rect: track, style: scrollbarStyle, character: " ")

        let thumbHeight = max(1, frame.height * frame.height / max(1, contentHeight))
        let travel = max(0, frame.height - thumbHeight)
        let thumbY = frame.y + (maxScrollOffset == 0 ? 0 : (scrollOffset * travel / maxScrollOffset))
        canvas.fill(rect: Rect(x: x, y: thumbY, width: width, height: thumbHeight), style: thumbStyle, character: " ")
    }
}

public enum ScrollViewCommand: Equatable, Sendable {
    case none
    case focused
    case scrolled(Int)
}
