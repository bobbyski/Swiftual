import Foundation

public struct RichLogEntry: Equatable, Sendable {
    public var message: String
    public var style: TerminalStyle

    public init(
        _ message: String,
        style: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black)
    ) {
        self.message = message
        self.style = style
    }
}

public struct RichLog: CanvasRenderable, Equatable, Sendable {
    public var frame: Rect
    public var entries: [RichLogEntry]
    public var maxEntries: Int
    public var fillStyle: TerminalStyle
    public var titleStyle: TerminalStyle
    public var title: String

    public init(
        frame: Rect,
        entries: [RichLogEntry] = [],
        maxEntries: Int = 200,
        title: String = "Rich log",
        fillStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        titleStyle: TerminalStyle = TerminalStyle(foreground: .black, background: .cyan, bold: true)
    ) {
        self.frame = frame
        self.entries = Array(entries.suffix(max(0, maxEntries)))
        self.maxEntries = maxEntries
        self.fillStyle = fillStyle
        self.titleStyle = titleStyle
        self.title = title
    }

    public mutating func append(_ message: String, style: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black)) {
        entries.append(RichLogEntry(message, style: style))
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    public func render(in canvas: inout Canvas) {
        guard frame.width > 0, frame.height > 0 else { return }
        canvas.fill(rect: frame, style: fillStyle)
        renderTitle(in: &canvas)

        let contentY = frame.y + 1
        let contentHeight = max(0, frame.height - 1)
        guard contentHeight > 0 else { return }

        let visibleEntries = entries.suffix(contentHeight)
        for (offset, entry) in visibleEntries.enumerated() {
            let y = contentY + offset
            let style = styleForEntry(entry)
            canvas.drawText(String(entry.message.prefix(frame.width)), at: Point(x: frame.x, y: y), style: style)
        }
    }

    private func renderTitle(in canvas: inout Canvas) {
        canvas.fill(rect: Rect(x: frame.x, y: frame.y, width: frame.width, height: 1), style: titleStyle)
        let text = " \(title) "
        canvas.drawText(String(text.prefix(frame.width)), at: Point(x: frame.x, y: frame.y), style: titleStyle)
    }

    private func styleForEntry(_ entry: RichLogEntry) -> TerminalStyle {
        TerminalStyle(
            foreground: entry.style.foreground,
            background: entry.style.background ?? fillStyle.background,
            bold: entry.style.bold,
            dim: entry.style.dim,
            italic: entry.style.italic,
            underline: entry.style.underline,
            strikethrough: entry.style.strikethrough,
            inverse: entry.style.inverse,
            blink: entry.style.blink
        )
    }
}
