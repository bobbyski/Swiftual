import Foundation

public struct Cell: Equatable, Sendable {
    public var character: Character
    public var style: TerminalStyle

    public init(_ character: Character = " ", style: TerminalStyle = .plain) {
        self.character = character
        self.style = style
    }
}

public struct Canvas: Equatable, Sendable {
    public let size: TerminalSize
    private var cells: [Cell]

    public init(size: TerminalSize, fill: Cell = Cell()) {
        self.size = size
        self.cells = Array(repeating: fill, count: size.columns * size.rows)
    }

    public subscript(x: Int, y: Int) -> Cell {
        get {
            guard contains(x: x, y: y) else { return Cell() }
            return cells[y * size.columns + x]
        }
        set {
            guard contains(x: x, y: y) else { return }
            cells[y * size.columns + x] = newValue
        }
    }

    public mutating func fill(rect: Rect, style: TerminalStyle, character: Character = " ") {
        let startRow = max(0, rect.y)
        let endRow = min(size.rows, rect.y + rect.height)
        let startColumn = max(0, rect.x)
        let endColumn = min(size.columns, rect.x + rect.width)
        guard startRow < endRow, startColumn < endColumn else { return }

        for row in startRow..<endRow {
            for column in startColumn..<endColumn {
                self[column, row] = Cell(character, style: style)
            }
        }
    }

    public mutating func drawText(_ text: String, at point: Point, style: TerminalStyle) {
        var column = point.x
        for character in text {
            guard column < size.columns else { return }
            if column >= 0 && point.y >= 0 && point.y < size.rows {
                self[column, point.y] = Cell(character, style: style)
            }
            column += 1
        }
    }

    public func rows() -> [[Cell]] {
        stride(from: 0, to: cells.count, by: size.columns).map { start in
            Array(cells[start..<min(start + size.columns, cells.count)])
        }
    }

    private func contains(x: Int, y: Int) -> Bool {
        x >= 0 && x < size.columns && y >= 0 && y < size.rows
    }
}
