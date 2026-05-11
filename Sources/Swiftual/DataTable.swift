import Foundation

public struct DataTableColumn: Equatable, Sendable {
    public var title: String
    public var width: Int

    public init(_ title: String, width: Int) {
        self.title = title
        self.width = max(1, width)
    }
}

public struct DataTableGridCharacters: Equatable, Sendable {
    public var topLeft: Character
    public var topSeparator: Character
    public var topRight: Character
    public var headerLeft: Character
    public var headerSeparator: Character
    public var headerRight: Character
    public var bottomLeft: Character
    public var bottomSeparator: Character
    public var bottomRight: Character
    public var horizontal: Character
    public var vertical: Character

    public init(
        topLeft: Character,
        topSeparator: Character,
        topRight: Character,
        headerLeft: Character,
        headerSeparator: Character,
        headerRight: Character,
        bottomLeft: Character,
        bottomSeparator: Character,
        bottomRight: Character,
        horizontal: Character,
        vertical: Character
    ) {
        self.topLeft = topLeft
        self.topSeparator = topSeparator
        self.topRight = topRight
        self.headerLeft = headerLeft
        self.headerSeparator = headerSeparator
        self.headerRight = headerRight
        self.bottomLeft = bottomLeft
        self.bottomSeparator = bottomSeparator
        self.bottomRight = bottomRight
        self.horizontal = horizontal
        self.vertical = vertical
    }

    public static let single = DataTableGridCharacters(
        topLeft: "┌", topSeparator: "┬", topRight: "┐",
        headerLeft: "├", headerSeparator: "┼", headerRight: "┤",
        bottomLeft: "└", bottomSeparator: "┴", bottomRight: "┘",
        horizontal: "─", vertical: "│"
    )

    public static let double = DataTableGridCharacters(
        topLeft: "╔", topSeparator: "╦", topRight: "╗",
        headerLeft: "╠", headerSeparator: "╬", headerRight: "╣",
        bottomLeft: "╚", bottomSeparator: "╩", bottomRight: "╝",
        horizontal: "═", vertical: "║"
    )

    public static let rounded = DataTableGridCharacters(
        topLeft: "╭", topSeparator: "┬", topRight: "╮",
        headerLeft: "├", headerSeparator: "┼", headerRight: "┤",
        bottomLeft: "╰", bottomSeparator: "┴", bottomRight: "╯",
        horizontal: "─", vertical: "│"
    )

    public static let dashed = DataTableGridCharacters(
        topLeft: "┌", topSeparator: "┬", topRight: "┐",
        headerLeft: "├", headerSeparator: "┼", headerRight: "┤",
        bottomLeft: "└", bottomSeparator: "┴", bottomRight: "┘",
        horizontal: "╌", vertical: "╎"
    )

    public static let ascii = DataTableGridCharacters(
        topLeft: "+", topSeparator: "+", topRight: "+",
        headerLeft: "+", headerSeparator: "+", headerRight: "+",
        bottomLeft: "+", bottomSeparator: "+", bottomRight: "+",
        horizontal: "-", vertical: "|"
    )
}

public struct DataTableGridStyle: Equatable, Sendable {
    public var characters: DataTableGridCharacters

    public init(characters: DataTableGridCharacters = .single) {
        self.characters = characters
    }

    public static let single = DataTableGridStyle(characters: .single)
    public static let double = DataTableGridStyle(characters: .double)
    public static let rounded = DataTableGridStyle(characters: .rounded)
    public static let dashed = DataTableGridStyle(characters: .dashed)
    public static let ascii = DataTableGridStyle(characters: .ascii)
}

public enum DataTablePresentation: Equatable, Sendable {
    case compact
    case framed(DataTableGridStyle)
    case grid(DataTableGridStyle)
}

public struct DataTable: CanvasRenderable, Equatable, Sendable {
    public var frame: Rect
    public var columns: [DataTableColumn]
    public var rows: [[String]]
    public var selectedRowIndex: Int
    public var scrollOffset: Int
    public var isFocused: Bool
    public var headerStyle: TerminalStyle
    public var rowStyle: TerminalStyle
    public var alternateRowStyle: TerminalStyle
    public var selectedRowStyle: TerminalStyle
    public var focusedSelectedRowStyle: TerminalStyle
    public var presentation: DataTablePresentation

    public init(
        frame: Rect,
        columns: [DataTableColumn],
        rows: [[String]],
        selectedRowIndex: Int = 0,
        scrollOffset: Int = 0,
        isFocused: Bool = false,
        headerStyle: TerminalStyle = TerminalStyle(foreground: .black, background: .cyan, bold: true),
        rowStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        alternateRowStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .brightBlack),
        selectedRowStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue),
        focusedSelectedRowStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true),
        presentation: DataTablePresentation = .compact
    ) {
        self.frame = frame
        self.columns = columns
        self.rows = rows
        self.selectedRowIndex = rows.indices.contains(selectedRowIndex) ? selectedRowIndex : 0
        self.scrollOffset = min(max(0, scrollOffset), max(0, rows.count - DataTable.visibleRowCapacity(frameHeight: frame.height, presentation: presentation)))
        self.isFocused = isFocused
        self.headerStyle = headerStyle
        self.rowStyle = rowStyle
        self.alternateRowStyle = alternateRowStyle
        self.selectedRowStyle = selectedRowStyle
        self.focusedSelectedRowStyle = focusedSelectedRowStyle
        self.presentation = presentation
    }

    public var selectedRow: [String]? {
        guard rows.indices.contains(selectedRowIndex) else { return nil }
        return rows[selectedRowIndex]
    }

    public mutating func handle(_ event: InputEvent) -> DataTableCommand {
        switch event {
        case .key(.down):
            guard isFocused else { return .none }
            return moveSelection(delta: 1)
        case .key(.up):
            guard isFocused else { return .none }
            return moveSelection(delta: -1)
        case .key(.enter), .key(.character(" ")):
            guard isFocused, let selectedRow else { return .none }
            return .activated(selectedRowIndex, selectedRow)
        case .mouse(let mouse):
            guard mouse.pressed, mouse.button == .left, frame.contains(mouse.location) else { return .none }
            isFocused = true
            guard let rowOffset = rowOffset(at: mouse.location.y) else { return .focused }
            let rowIndex = scrollOffset + rowOffset
            guard rows.indices.contains(rowIndex) else { return .focused }
            selectedRowIndex = rowIndex
            ensureSelectionVisible()
            return .selected(rowIndex, rows[rowIndex])
        default:
            return .none
        }
    }

    public func render(in canvas: inout Canvas) {
        guard frame.width > 0, frame.height > 0 else { return }
        switch presentation {
        case .compact:
            renderCompact(in: &canvas)
        case .framed(let gridStyle):
            renderFramed(gridStyle, in: &canvas)
        case .grid(let gridStyle):
            renderGrid(gridStyle, in: &canvas)
        }
    }

    private mutating func moveSelection(delta: Int) -> DataTableCommand {
        guard !rows.isEmpty else { return .none }
        let old = selectedRowIndex
        selectedRowIndex = min(max(0, selectedRowIndex + delta), rows.count - 1)
        ensureSelectionVisible()
        return old == selectedRowIndex ? .none : .selected(selectedRowIndex, rows[selectedRowIndex])
    }

    private mutating func ensureSelectionVisible() {
        let visibleHeight = visibleRowCapacity
        guard visibleHeight > 0 else {
            scrollOffset = 0
            return
        }
        if selectedRowIndex < scrollOffset {
            scrollOffset = selectedRowIndex
        } else if selectedRowIndex >= scrollOffset + visibleHeight {
            scrollOffset = selectedRowIndex - visibleHeight + 1
        }
    }

    private var visibleRowCapacity: Int {
        DataTable.visibleRowCapacity(frameHeight: frame.height, presentation: presentation)
    }

    private static func visibleRowCapacity(frameHeight: Int, presentation: DataTablePresentation) -> Int {
        switch presentation {
        case .compact:
            max(0, frameHeight - 1)
        case .framed:
            max(0, frameHeight - 4)
        case .grid:
            max(0, (frameHeight - 3) / 2)
        }
    }

    private func rowOffset(at y: Int) -> Int? {
        switch presentation {
        case .compact:
            guard y > frame.y else { return nil }
            return y - frame.y - 1
        case .framed:
            let rowStart = frame.y + 3
            guard y >= rowStart, y < frame.y + frame.height - 1 else { return nil }
            return y - rowStart
        case .grid:
            let rowStart = frame.y + 3
            guard y >= rowStart, y < frame.y + frame.height - 1 else { return nil }
            let delta = y - rowStart
            guard delta.isMultiple(of: 2) else { return nil }
            return delta / 2
        }
    }

    private func renderCompact(in canvas: inout Canvas) {
        canvas.fill(rect: frame, style: rowStyle)
        renderHeader(in: &canvas)

        let visibleHeight = visibleRowCapacity
        guard visibleHeight > 0 else { return }
        for offset in 0..<visibleHeight {
            let rowIndex = scrollOffset + offset
            guard rows.indices.contains(rowIndex) else { break }
            renderRow(rows[rowIndex], rowIndex: rowIndex, y: frame.y + 1 + offset, in: &canvas)
        }
    }

    private func renderGrid(_ gridStyle: DataTableGridStyle, in canvas: inout Canvas) {
        canvas.fill(rect: frame, style: rowStyle)
        renderGridRule(
            left: gridStyle.characters.topLeft,
            separator: gridStyle.characters.topSeparator,
            right: gridStyle.characters.topRight,
            horizontal: gridStyle.characters.horizontal,
            y: frame.y,
            style: headerStyle,
            in: &canvas
        )
        renderGridCells(columns.map(\.title), y: frame.y + 1, style: headerStyle, characters: gridStyle.characters, in: &canvas)
        renderGridRule(
            left: gridStyle.characters.headerLeft,
            separator: gridStyle.characters.headerSeparator,
            right: gridStyle.characters.headerRight,
            horizontal: gridStyle.characters.horizontal,
            y: frame.y + 2,
            style: headerStyle,
            in: &canvas
        )

        let visibleHeight = visibleRowCapacity
        for offset in 0..<visibleHeight {
            let rowIndex = scrollOffset + offset
            guard rows.indices.contains(rowIndex) else { break }
            let rowY = frame.y + 3 + (offset * 2)
            renderGridRow(rows[rowIndex], rowIndex: rowIndex, y: rowY, characters: gridStyle.characters, in: &canvas)
            if offset < visibleHeight - 1, rowY + 1 < frame.y + frame.height - 1 {
                renderGridRule(
                    left: gridStyle.characters.headerLeft,
                    separator: gridStyle.characters.headerSeparator,
                    right: gridStyle.characters.headerRight,
                    horizontal: gridStyle.characters.horizontal,
                    y: rowY + 1,
                    style: rowStyle(for: rowIndex),
                    in: &canvas
                )
            }
        }

        renderGridRule(
            left: gridStyle.characters.bottomLeft,
            separator: gridStyle.characters.bottomSeparator,
            right: gridStyle.characters.bottomRight,
            horizontal: gridStyle.characters.horizontal,
            y: frame.y + frame.height - 1,
            style: rowStyle,
            in: &canvas
        )
    }

    private func renderFramed(_ gridStyle: DataTableGridStyle, in canvas: inout Canvas) {
        canvas.fill(rect: frame, style: rowStyle)
        renderGridRule(
            left: gridStyle.characters.topLeft,
            separator: gridStyle.characters.topSeparator,
            right: gridStyle.characters.topRight,
            horizontal: gridStyle.characters.horizontal,
            y: frame.y,
            style: rowStyle,
            in: &canvas
        )
        renderGridCells(columns.map(\.title), y: frame.y + 1, style: headerStyle, characters: gridStyle.characters, in: &canvas)
        renderGridRule(
            left: gridStyle.characters.headerLeft,
            separator: gridStyle.characters.headerSeparator,
            right: gridStyle.characters.headerRight,
            horizontal: gridStyle.characters.horizontal,
            y: frame.y + 2,
            style: headerStyle,
            in: &canvas
        )

        let visibleHeight = visibleRowCapacity
        for offset in 0..<visibleHeight {
            let rowIndex = scrollOffset + offset
            guard rows.indices.contains(rowIndex) else { break }
            renderGridRow(rows[rowIndex], rowIndex: rowIndex, y: frame.y + 3 + offset, characters: gridStyle.characters, in: &canvas)
        }

        renderGridRule(
            left: gridStyle.characters.bottomLeft,
            separator: gridStyle.characters.bottomSeparator,
            right: gridStyle.characters.bottomRight,
            horizontal: gridStyle.characters.horizontal,
            y: frame.y + frame.height - 1,
            style: rowStyle,
            in: &canvas
        )
    }

    private func renderHeader(in canvas: inout Canvas) {
        canvas.fill(rect: Rect(x: frame.x, y: frame.y, width: frame.width, height: 1), style: headerStyle)
        renderCells(columns.map(\.title), y: frame.y, style: headerStyle, frame: frame, separator: "|", in: &canvas)
    }

    private func renderRow(_ row: [String], rowIndex: Int, y: Int, in canvas: inout Canvas) {
        renderRow(row, rowIndex: rowIndex, y: y, frame: frame, separator: "|", in: &canvas)
    }

    private func renderRow(_ row: [String], rowIndex: Int, y: Int, frame: Rect, separator: Character, in canvas: inout Canvas) {
        let style: TerminalStyle
        if rowIndex == selectedRowIndex {
            style = isFocused ? focusedSelectedRowStyle : selectedRowStyle
        } else if rowIndex.isMultiple(of: 2) {
            style = rowStyle
        } else {
            style = alternateRowStyle
        }
        canvas.fill(rect: Rect(x: frame.x, y: y, width: frame.width, height: 1), style: style)
        renderCells(row, y: y, style: style, frame: frame, separator: separator, in: &canvas)
    }

    private func renderGridRow(_ row: [String], rowIndex: Int, y: Int, characters: DataTableGridCharacters, in canvas: inout Canvas) {
        let style = rowStyle(for: rowIndex)
        canvas.fill(rect: Rect(x: frame.x, y: y, width: frame.width, height: 1), style: style)
        renderGridCells(row, y: y, style: style, characters: characters, in: &canvas)
    }

    private func rowStyle(for rowIndex: Int) -> TerminalStyle {
        if rowIndex == selectedRowIndex {
            isFocused ? focusedSelectedRowStyle : selectedRowStyle
        } else if rowIndex.isMultiple(of: 2) {
            rowStyle
        } else {
            alternateRowStyle
        }
    }

    private func renderCells(_ cells: [String], y: Int, style: TerminalStyle, frame: Rect, separator: Character, in canvas: inout Canvas) {
        var x = frame.x
        for columnIndex in columns.indices {
            guard x < frame.x + frame.width else { return }
            let column = columns[columnIndex]
            if columnIndex > 0 {
                canvas.drawText(String(separator), at: Point(x: x, y: y), style: style)
                x += 1
            }
            let width = min(column.width, max(0, frame.x + frame.width - x))
            guard width > 0 else { return }
            let value = cells.indices.contains(columnIndex) ? cells[columnIndex] : ""
            let text = String((" " + value).prefix(width))
            canvas.drawText(text, at: Point(x: x, y: y), style: style)
            x += width
        }
    }

    private func renderGridCells(_ cells: [String], y: Int, style: TerminalStyle, characters: DataTableGridCharacters, in canvas: inout Canvas) {
        var x = frame.x
        guard x < frame.x + frame.width else { return }
        canvas.drawText(String(characters.vertical), at: Point(x: x, y: y), style: style)
        x += 1
        for columnIndex in columns.indices {
            let column = columns[columnIndex]
            let width = min(column.width, max(0, frame.x + frame.width - x - 1))
            guard width > 0 else { return }
            let value = cells.indices.contains(columnIndex) ? cells[columnIndex] : ""
            let text = String((" " + value).prefix(width)).padding(toLength: width, withPad: " ", startingAt: 0)
            canvas.drawText(text, at: Point(x: x, y: y), style: style)
            x += width
            guard x < frame.x + frame.width else { return }
            canvas.drawText(String(characters.vertical), at: Point(x: x, y: y), style: style)
            x += 1
        }
    }

    private func renderGridRule(
        left: Character,
        separator: Character,
        right: Character,
        horizontal: Character,
        y: Int,
        style: TerminalStyle,
        in canvas: inout Canvas
    ) {
        guard y >= frame.y, y < frame.y + frame.height else { return }
        var x = frame.x
        guard x < frame.x + frame.width else { return }
        canvas.drawText(String(left), at: Point(x: x, y: y), style: style)
        x += 1
        for columnIndex in columns.indices {
            let width = min(columns[columnIndex].width, max(0, frame.x + frame.width - x - 1))
            guard width > 0 else { return }
            canvas.drawText(String(repeating: String(horizontal), count: width), at: Point(x: x, y: y), style: style)
            x += width
            guard x < frame.x + frame.width else { return }
            let character = columnIndex == columns.count - 1 ? right : separator
            canvas.drawText(String(character), at: Point(x: x, y: y), style: style)
            x += 1
        }
    }
}

public enum DataTableCommand: Equatable, Sendable {
    case none
    case focused
    case selected(Int, [String])
    case activated(Int, [String])
}
