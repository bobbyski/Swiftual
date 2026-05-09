import Foundation

public struct DataTableColumn: Equatable, Sendable {
    public var title: String
    public var width: Int

    public init(_ title: String, width: Int) {
        self.title = title
        self.width = max(1, width)
    }
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
        focusedSelectedRowStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true)
    ) {
        self.frame = frame
        self.columns = columns
        self.rows = rows
        self.selectedRowIndex = rows.indices.contains(selectedRowIndex) ? selectedRowIndex : 0
        self.scrollOffset = min(max(0, scrollOffset), max(0, rows.count - max(0, frame.height - 1)))
        self.isFocused = isFocused
        self.headerStyle = headerStyle
        self.rowStyle = rowStyle
        self.alternateRowStyle = alternateRowStyle
        self.selectedRowStyle = selectedRowStyle
        self.focusedSelectedRowStyle = focusedSelectedRowStyle
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
            guard mouse.location.y > frame.y else { return .focused }
            let rowIndex = scrollOffset + mouse.location.y - frame.y - 1
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
        canvas.fill(rect: frame, style: rowStyle)
        renderHeader(in: &canvas)

        let visibleHeight = max(0, frame.height - 1)
        guard visibleHeight > 0 else { return }
        for offset in 0..<visibleHeight {
            let rowIndex = scrollOffset + offset
            guard rows.indices.contains(rowIndex) else { break }
            renderRow(rows[rowIndex], rowIndex: rowIndex, y: frame.y + 1 + offset, in: &canvas)
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
        let visibleHeight = max(0, frame.height - 1)
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

    private func renderHeader(in canvas: inout Canvas) {
        canvas.fill(rect: Rect(x: frame.x, y: frame.y, width: frame.width, height: 1), style: headerStyle)
        renderCells(columns.map(\.title), y: frame.y, style: headerStyle, in: &canvas)
    }

    private func renderRow(_ row: [String], rowIndex: Int, y: Int, in canvas: inout Canvas) {
        let style: TerminalStyle
        if rowIndex == selectedRowIndex {
            style = isFocused ? focusedSelectedRowStyle : selectedRowStyle
        } else if rowIndex.isMultiple(of: 2) {
            style = rowStyle
        } else {
            style = alternateRowStyle
        }
        canvas.fill(rect: Rect(x: frame.x, y: y, width: frame.width, height: 1), style: style)
        renderCells(row, y: y, style: style, in: &canvas)
    }

    private func renderCells(_ cells: [String], y: Int, style: TerminalStyle, in canvas: inout Canvas) {
        var x = frame.x
        for columnIndex in columns.indices {
            guard x < frame.x + frame.width else { return }
            let column = columns[columnIndex]
            if columnIndex > 0 {
                canvas.drawText("|", at: Point(x: x, y: y), style: style)
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
}

public enum DataTableCommand: Equatable, Sendable {
    case none
    case focused
    case selected(Int, [String])
    case activated(Int, [String])
}
