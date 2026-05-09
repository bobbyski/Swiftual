import Foundation

public struct CommandPaletteItem: Equatable, Sendable {
    public var title: String
    public var detail: String
    public var isEnabled: Bool

    public init(_ title: String, detail: String = "", isEnabled: Bool = true) {
        self.title = title
        self.detail = detail
        self.isEnabled = isEnabled
    }
}

public struct CommandPalette: CanvasRenderable, Equatable, Sendable {
    public var frame: Rect
    public var title: String
    public var items: [CommandPaletteItem]
    public var query: String
    public var highlightedIndex: Int
    public var isPresented: Bool
    public var panelStyle: TerminalStyle
    public var titleStyle: TerminalStyle
    public var inputStyle: TerminalStyle
    public var itemStyle: TerminalStyle
    public var highlightedStyle: TerminalStyle
    public var disabledStyle: TerminalStyle

    public init(
        frame: Rect,
        title: String = "Command palette",
        items: [CommandPaletteItem],
        query: String = "",
        highlightedIndex: Int = 0,
        isPresented: Bool = false,
        panelStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        titleStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true),
        inputStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .brightBlack),
        itemStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        highlightedStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true),
        disabledStyle: TerminalStyle = TerminalStyle(foreground: .white, background: .brightBlack)
    ) {
        self.frame = frame
        self.title = title
        self.items = items
        self.query = query
        self.highlightedIndex = highlightedIndex
        self.isPresented = isPresented
        self.panelStyle = panelStyle
        self.titleStyle = titleStyle
        self.inputStyle = inputStyle
        self.itemStyle = itemStyle
        self.highlightedStyle = highlightedStyle
        self.disabledStyle = disabledStyle
        clampHighlight()
    }

    public var filteredItems: [CommandPaletteItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return items }
        return items.filter { item in
            item.title.localizedCaseInsensitiveContains(trimmed) ||
                item.detail.localizedCaseInsensitiveContains(trimmed)
        }
    }

    public mutating func present() {
        isPresented = true
        query = ""
        highlightedIndex = firstEnabledIndex(in: filteredItems)
    }

    public mutating func dismiss() {
        isPresented = false
    }

    public mutating func handle(_ event: InputEvent) -> CommandPaletteCommand {
        guard isPresented else { return .none }

        switch event {
        case .key(.escape):
            dismiss()
            return .dismissed
        case .key(.up):
            moveHighlight(delta: -1)
            return .highlighted(highlightedIndex)
        case .key(.down), .key(.tab):
            moveHighlight(delta: 1)
            return .highlighted(highlightedIndex)
        case .key(.enter):
            return selectHighlighted()
        case .key(.backspace):
            guard !query.isEmpty else { return .none }
            query.removeLast()
            clampHighlight()
            return .queryChanged(query)
        case .key(.character(let character)):
            guard !character.isNewline, character != "\t" else { return .none }
            query.append(character)
            clampHighlight()
            return .queryChanged(query)
        case .mouse(let mouse):
            guard mouse.pressed, mouse.button == .left else { return .none }
            if let index = itemIndex(at: mouse.location) {
                highlightedIndex = index
                return selectHighlighted()
            }
            if !frame.contains(mouse.location) {
                dismiss()
                return .dismissed
            }
            return .none
        default:
            return .none
        }
    }

    public func render(in canvas: inout Canvas) {
        guard isPresented, frame.width > 0, frame.height > 0 else { return }
        canvas.fill(rect: frame, style: panelStyle)
        canvas.fill(rect: Rect(x: frame.x, y: frame.y, width: frame.width, height: 1), style: titleStyle)
        canvas.drawText(String((" " + title).prefix(frame.width)), at: Point(x: frame.x, y: frame.y), style: titleStyle)

        let queryFrame = Rect(x: frame.x + 1, y: frame.y + 2, width: max(0, frame.width - 2), height: 1)
        canvas.fill(rect: queryFrame, style: inputStyle)
        let inputText = "> " + query
        canvas.drawText(String(inputText.suffix(queryFrame.width)), at: Point(x: queryFrame.x, y: queryFrame.y), style: inputStyle)

        let rows = Array(filteredItems.prefix(max(0, frame.height - 4)))
        if rows.isEmpty {
            canvas.drawText(" No matches", at: Point(x: frame.x + 1, y: frame.y + 4), style: disabledStyle)
            return
        }

        for (offset, item) in rows.enumerated() {
            let y = frame.y + 4 + offset
            let style: TerminalStyle
            if !item.isEnabled {
                style = disabledStyle
            } else if offset == highlightedIndex {
                style = highlightedStyle
            } else {
                style = itemStyle
            }
            let rowFrame = Rect(x: frame.x + 1, y: y, width: max(0, frame.width - 2), height: 1)
            canvas.fill(rect: rowFrame, style: style)
            canvas.drawText(String(rowText(for: item, width: rowFrame.width).prefix(rowFrame.width)), at: Point(x: rowFrame.x, y: rowFrame.y), style: style)
        }
    }

    private func rowText(for item: CommandPaletteItem, width: Int) -> String {
        guard !item.detail.isEmpty, width > item.title.count + 4 else {
            return " " + item.title
        }
        let detailWidth = max(0, width - item.title.count - 3)
        return " \(item.title) " + String(item.detail.prefix(detailWidth))
    }

    private mutating func selectHighlighted() -> CommandPaletteCommand {
        let rows = filteredItems
        guard rows.indices.contains(highlightedIndex), rows[highlightedIndex].isEnabled else { return .none }
        let item = rows[highlightedIndex]
        dismiss()
        return .selected(item.title)
    }

    private mutating func moveHighlight(delta: Int) {
        let rows = filteredItems
        guard !rows.isEmpty else {
            highlightedIndex = 0
            return
        }

        var next = highlightedIndex
        for _ in rows.indices {
            next = (next + delta + rows.count) % rows.count
            if rows[next].isEnabled {
                highlightedIndex = next
                return
            }
        }
    }

    private mutating func clampHighlight() {
        let rows = filteredItems
        guard !rows.isEmpty else {
            highlightedIndex = 0
            return
        }
        if !rows.indices.contains(highlightedIndex) || !rows[highlightedIndex].isEnabled {
            highlightedIndex = firstEnabledIndex(in: rows)
        }
    }

    private func firstEnabledIndex(in rows: [CommandPaletteItem]) -> Int {
        rows.firstIndex(where: \.isEnabled) ?? 0
    }

    private func itemIndex(at point: Point) -> Int? {
        let rows = filteredItems
        let firstY = frame.y + 4
        guard point.x >= frame.x + 1,
              point.x < frame.x + frame.width - 1,
              point.y >= firstY
        else {
            return nil
        }
        let index = point.y - firstY
        return rows.indices.contains(index) ? index : nil
    }
}

public enum CommandPaletteCommand: Equatable, Sendable {
    case none
    case dismissed
    case highlighted(Int)
    case queryChanged(String)
    case selected(String)
}
