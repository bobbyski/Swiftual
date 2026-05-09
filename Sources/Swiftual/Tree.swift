import Foundation

public struct TreeNode: Equatable, Sendable {
    public var title: String
    public var children: [TreeNode]
    public var isExpanded: Bool

    public init(_ title: String, isExpanded: Bool = true, children: [TreeNode] = []) {
        self.title = title
        self.children = children
        self.isExpanded = isExpanded
    }

    public var hasChildren: Bool {
        !children.isEmpty
    }
}

public struct TreeRow: Equatable, Sendable {
    public var path: [Int]
    public var title: String
    public var depth: Int
    public var isExpanded: Bool
    public var hasChildren: Bool
}

public struct Tree: CanvasRenderable, Equatable, Sendable {
    public var frame: Rect
    public var roots: [TreeNode]
    public var selectedPath: [Int]
    public var scrollOffset: Int
    public var isFocused: Bool
    public var fillStyle: TerminalStyle
    public var rowStyle: TerminalStyle
    public var selectedStyle: TerminalStyle
    public var focusedSelectedStyle: TerminalStyle
    public var branchStyle: TerminalStyle
    public var scrollbarStyle: TerminalStyle
    public var thumbStyle: TerminalStyle

    public init(
        frame: Rect,
        roots: [TreeNode],
        selectedPath: [Int] = [0],
        scrollOffset: Int = 0,
        isFocused: Bool = false,
        fillStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        rowStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        selectedStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue),
        focusedSelectedStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true),
        branchStyle: TerminalStyle = TerminalStyle(foreground: .cyan, background: .black),
        scrollbarStyle: TerminalStyle = TerminalStyle(foreground: .white, background: .brightBlack),
        thumbStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true)
    ) {
        self.frame = frame
        self.roots = roots
        self.selectedPath = Tree.node(at: selectedPath, in: roots) == nil ? (roots.isEmpty ? [] : [0]) : selectedPath
        self.scrollOffset = max(0, scrollOffset)
        self.isFocused = isFocused
        self.fillStyle = fillStyle
        self.rowStyle = rowStyle
        self.selectedStyle = selectedStyle
        self.focusedSelectedStyle = focusedSelectedStyle
        self.branchStyle = branchStyle
        self.scrollbarStyle = scrollbarStyle
        self.thumbStyle = thumbStyle
        clampScrollOffset()
    }

    public var visibleRows: [TreeRow] {
        var rows: [TreeRow] = []
        for index in roots.indices {
            appendVisibleRows(node: roots[index], path: [index], depth: 0, to: &rows)
        }
        return rows
    }

    public var selectedRow: TreeRow? {
        visibleRows.first { $0.path == selectedPath }
    }

    public mutating func handle(_ event: InputEvent) -> TreeCommand {
        switch event {
        case .key(.down):
            guard isFocused else { return .none }
            return moveSelection(delta: 1)
        case .key(.up):
            guard isFocused else { return .none }
            return moveSelection(delta: -1)
        case .key(.right):
            guard isFocused else { return .none }
            return expandSelected()
        case .key(.left):
            guard isFocused else { return .none }
            return collapseSelectedOrMoveToParent()
        case .key(.enter), .key(.character(" ")):
            guard isFocused else { return .none }
            if let command = toggleSelected() {
                return command
            }
            guard let selectedRow else { return .none }
            return .activated(selectedRow)
        case .mouse(let mouse):
            if mouse.button == .left,
               mouse.pressed,
               showsScrollbar,
               mouse.location.x >= frame.x + frame.width - scrollbarWidth {
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
                guard mouse.pressed else { return .none }
            default:
                return .none
            }
            isFocused = true
            let visibleIndex = scrollOffset + mouse.location.y - frame.y
            let rows = visibleRows
            guard rows.indices.contains(visibleIndex) else { return .focused }
            selectedPath = rows[visibleIndex].path
            ensureSelectionVisible()
            if mouse.location.x <= frame.x + rows[visibleIndex].depth * 2 + 1,
               let command = toggleSelected() {
                return command
            }
            return .selected(rows[visibleIndex])
        default:
            return .none
        }
    }

    public func render(in canvas: inout Canvas) {
        guard frame.width > 0, frame.height > 0 else { return }
        canvas.fill(rect: frame, style: fillStyle)
        let rows = visibleRows
        for offset in 0..<frame.height {
            let rowIndex = scrollOffset + offset
            guard rows.indices.contains(rowIndex) else { break }
            render(row: rows[rowIndex], y: frame.y + offset, in: &canvas)
        }
        renderScrollbar(in: &canvas)
    }

    private mutating func moveSelection(delta: Int) -> TreeCommand {
        let rows = visibleRows
        guard let current = rows.firstIndex(where: { $0.path == selectedPath }) else { return .none }
        let next = min(max(0, current + delta), rows.count - 1)
        guard next != current else { return .none }
        selectedPath = rows[next].path
        ensureSelectionVisible()
        return .selected(rows[next])
    }

    private mutating func expandSelected() -> TreeCommand {
        guard let node = Self.node(at: selectedPath, in: roots), node.hasChildren else { return .none }
        guard !node.isExpanded else { return .none }
        setExpanded(true, at: selectedPath)
        ensureSelectionVisible()
        return .expanded(selectedRow ?? TreeRow(path: selectedPath, title: node.title, depth: selectedPath.count - 1, isExpanded: true, hasChildren: true))
    }

    private mutating func collapseSelectedOrMoveToParent() -> TreeCommand {
        if let node = Self.node(at: selectedPath, in: roots), node.hasChildren, node.isExpanded {
            setExpanded(false, at: selectedPath)
            ensureSelectionVisible()
            return .collapsed(selectedRow ?? TreeRow(path: selectedPath, title: node.title, depth: selectedPath.count - 1, isExpanded: false, hasChildren: true))
        }
        guard selectedPath.count > 1 else { return .none }
        selectedPath.removeLast()
        ensureSelectionVisible()
        guard let selectedRow else { return .none }
        return .selected(selectedRow)
    }

    private mutating func toggleSelected() -> TreeCommand? {
        guard let node = Self.node(at: selectedPath, in: roots), node.hasChildren else { return nil }
        let isExpanded = !node.isExpanded
        setExpanded(isExpanded, at: selectedPath)
        ensureSelectionVisible()
        let row = selectedRow ?? TreeRow(path: selectedPath, title: node.title, depth: selectedPath.count - 1, isExpanded: isExpanded, hasChildren: true)
        return isExpanded ? .expanded(row) : .collapsed(row)
    }

    private mutating func ensureSelectionVisible() {
        let rows = visibleRows
        guard let index = rows.firstIndex(where: { $0.path == selectedPath }), frame.height > 0 else {
            clampScrollOffset()
            return
        }
        if index < scrollOffset {
            scrollOffset = index
        } else if index >= scrollOffset + frame.height {
            scrollOffset = index - frame.height + 1
        }
        clampScrollOffset()
    }

    private mutating func clampScrollOffset() {
        scrollOffset = min(max(0, scrollOffset), max(0, visibleRows.count - frame.height))
    }

    private var showsScrollbar: Bool {
        visibleRows.count > frame.height
    }

    private var maxScrollOffset: Int {
        max(0, visibleRows.count - frame.height)
    }

    private var contentWidth: Int {
        max(0, frame.width - (showsScrollbar ? scrollbarWidth : 0))
    }

    private var scrollbarWidth: Int {
        2
    }

    private mutating func scroll(by delta: Int) -> TreeCommand {
        let old = scrollOffset
        scrollOffset = min(max(0, scrollOffset + delta), maxScrollOffset)
        return old == scrollOffset ? .none : .scrolled(scrollOffset)
    }

    private mutating func scroll(toThumbLocation location: Point) -> TreeCommand {
        guard showsScrollbar, frame.height > 0 else { return .none }
        let old = scrollOffset
        let relativeY = min(max(0, location.y - frame.y), frame.height - 1)
        let thumbHeight = max(1, frame.height * frame.height / max(1, visibleRows.count))
        let travel = max(1, frame.height - thumbHeight)
        scrollOffset = min(maxScrollOffset, max(0, relativeY * maxScrollOffset / travel))
        return old == scrollOffset ? .focused : .scrolled(scrollOffset)
    }

    private func appendVisibleRows(node: TreeNode, path: [Int], depth: Int, to rows: inout [TreeRow]) {
        rows.append(TreeRow(path: path, title: node.title, depth: depth, isExpanded: node.isExpanded, hasChildren: node.hasChildren))
        guard node.isExpanded else { return }
        for index in node.children.indices {
            appendVisibleRows(node: node.children[index], path: path + [index], depth: depth + 1, to: &rows)
        }
    }

    private func render(row: TreeRow, y: Int, in canvas: inout Canvas) {
        let style = row.path == selectedPath ? (isFocused ? focusedSelectedStyle : selectedStyle) : rowStyle
        canvas.fill(rect: Rect(x: frame.x, y: y, width: frame.width, height: 1), style: style)
        let marker: String
        if row.hasChildren {
            marker = row.isExpanded ? "v" : ">"
        } else {
            marker = "-"
        }
        let indent = String(repeating: "  ", count: row.depth)
        let text = "\(indent)\(marker) \(row.title)"
        canvas.drawText(String(text.prefix(contentWidth)), at: Point(x: frame.x, y: y), style: style)
    }

    private func renderScrollbar(in canvas: inout Canvas) {
        guard showsScrollbar, frame.width > 0 else { return }
        let width = min(scrollbarWidth, frame.width)
        let x = frame.x + frame.width - width
        canvas.fill(rect: Rect(x: x, y: frame.y, width: width, height: frame.height), style: scrollbarStyle)

        let thumbHeight = max(1, frame.height * frame.height / max(1, visibleRows.count))
        let travel = max(0, frame.height - thumbHeight)
        let thumbY = frame.y + (maxScrollOffset == 0 ? 0 : (scrollOffset * travel / maxScrollOffset))
        canvas.fill(rect: Rect(x: x, y: thumbY, width: width, height: thumbHeight), style: thumbStyle)
    }

    private static func node(at path: [Int], in nodes: [TreeNode]) -> TreeNode? {
        guard let first = path.first, nodes.indices.contains(first) else { return nil }
        if path.count == 1 { return nodes[first] }
        return node(at: Array(path.dropFirst()), in: nodes[first].children)
    }

    private mutating func setExpanded(_ isExpanded: Bool, at path: [Int]) {
        setExpanded(isExpanded, at: path, in: &roots)
    }

    private func setExpanded(_ isExpanded: Bool, at path: [Int], in nodes: inout [TreeNode]) {
        guard let first = path.first, nodes.indices.contains(first) else { return }
        if path.count == 1 {
            nodes[first].isExpanded = isExpanded
            return
        }
        setExpanded(isExpanded, at: Array(path.dropFirst()), in: &nodes[first].children)
    }
}

public enum TreeCommand: Equatable, Sendable {
    case none
    case focused
    case selected(TreeRow)
    case expanded(TreeRow)
    case collapsed(TreeRow)
    case activated(TreeRow)
    case scrolled(Int)
}
