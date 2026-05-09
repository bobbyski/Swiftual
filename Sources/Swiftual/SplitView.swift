import Foundation

public enum SplitViewCommand: Equatable, Sendable {
    case none
    case focused
    case resized(Int)
}

public struct HorizontalSplitView: CanvasRenderable, Equatable, Sendable {
    public var frame: Rect
    public var dividerOffset: Int
    public var dividerWidth: Int
    public var minLeading: Int
    public var minTrailing: Int
    public var isClamped: Bool
    public var isDragging: Bool
    public var dividerStyle: TerminalStyle

    public init(
        frame: Rect,
        dividerOffset: Int,
        dividerWidth: Int = 1,
        minLeading: Int = 10,
        minTrailing: Int = 10,
        isClamped: Bool = true,
        isDragging: Bool = false,
        dividerStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue)
    ) {
        self.frame = frame
        self.dividerOffset = dividerOffset
        self.dividerWidth = max(1, dividerWidth)
        self.minLeading = max(0, minLeading)
        self.minTrailing = max(0, minTrailing)
        self.isClamped = isClamped
        self.isDragging = isDragging
        self.dividerStyle = dividerStyle
    }

    public var leadingFrame: Rect {
        Rect(x: frame.x, y: frame.y, width: clampedDividerOffset, height: frame.height)
    }

    public var dividerFrame: Rect {
        Rect(x: frame.x + clampedDividerOffset, y: frame.y, width: dividerWidth, height: frame.height)
    }

    public var trailingFrame: Rect {
        let dividerEnd = frame.x + clampedDividerOffset + dividerWidth
        let trailingWidth = max(0, frame.x + frame.width - dividerEnd)
        return Rect(x: dividerEnd, y: frame.y, width: trailingWidth, height: frame.height)
    }

    public mutating func handle(_ event: InputEvent) -> SplitViewCommand {
        guard case .mouse(let mouse) = event else { return .none }

        if mouse.button == .release || !mouse.pressed {
            guard isDragging else { return .none }
            isDragging = false
            return .focused
        }

        guard mouse.button == .left else { return .none }
        guard isDragging || dividerFrame.contains(mouse.location) else { return .none }

        isDragging = true
        let oldOffset = clampedDividerOffset
        dividerOffset = clampDividerOffset(mouse.location.x - frame.x)
        return oldOffset == clampedDividerOffset ? .focused : .resized(clampedDividerOffset)
    }

    public func render(in canvas: inout Canvas) {
        canvas.fill(rect: dividerFrame, style: dividerStyle)
    }

    public func render(
        leading: AnyCanvasRenderable?,
        trailing: AnyCanvasRenderable?,
        in canvas: inout Canvas
    ) {
        if var leading {
            leading.frame = leadingFrame
            leading.render(in: &canvas)
        }
        if var trailing {
            trailing.frame = trailingFrame
            trailing.render(in: &canvas)
        }
        render(in: &canvas)
    }

    private var clampedDividerOffset: Int {
        clampDividerOffset(dividerOffset)
    }

    private func clampDividerOffset(_ offset: Int) -> Int {
        guard isClamped else {
            return min(max(0, offset), max(0, frame.width - dividerWidth))
        }
        let maximum = max(minLeading, frame.width - dividerWidth - minTrailing)
        return min(max(minLeading, offset), maximum)
    }
}

public struct VerticalSplitView: CanvasRenderable, Equatable, Sendable {
    public var frame: Rect
    public var dividerOffset: Int
    public var dividerHeight: Int
    public var minTop: Int
    public var minBottom: Int
    public var isClamped: Bool
    public var isDragging: Bool
    public var dividerStyle: TerminalStyle

    public init(
        frame: Rect,
        dividerOffset: Int,
        dividerHeight: Int = 1,
        minTop: Int = 3,
        minBottom: Int = 3,
        isClamped: Bool = true,
        isDragging: Bool = false,
        dividerStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue)
    ) {
        self.frame = frame
        self.dividerOffset = dividerOffset
        self.dividerHeight = max(1, dividerHeight)
        self.minTop = max(0, minTop)
        self.minBottom = max(0, minBottom)
        self.isClamped = isClamped
        self.isDragging = isDragging
        self.dividerStyle = dividerStyle
    }

    public var topFrame: Rect {
        Rect(x: frame.x, y: frame.y, width: frame.width, height: clampedDividerOffset)
    }

    public var dividerFrame: Rect {
        Rect(x: frame.x, y: frame.y + clampedDividerOffset, width: frame.width, height: dividerHeight)
    }

    public var bottomFrame: Rect {
        let dividerEnd = frame.y + clampedDividerOffset + dividerHeight
        let bottomHeight = max(0, frame.y + frame.height - dividerEnd)
        return Rect(x: frame.x, y: dividerEnd, width: frame.width, height: bottomHeight)
    }

    public mutating func handle(_ event: InputEvent) -> SplitViewCommand {
        guard case .mouse(let mouse) = event else { return .none }

        if mouse.button == .release || !mouse.pressed {
            guard isDragging else { return .none }
            isDragging = false
            return .focused
        }

        guard mouse.button == .left else { return .none }
        guard isDragging || dividerFrame.contains(mouse.location) else { return .none }

        isDragging = true
        let oldOffset = clampedDividerOffset
        dividerOffset = clampDividerOffset(mouse.location.y - frame.y)
        return oldOffset == clampedDividerOffset ? .focused : .resized(clampedDividerOffset)
    }

    public func render(in canvas: inout Canvas) {
        canvas.fill(rect: dividerFrame, style: dividerStyle)
    }

    public func render(
        top: AnyCanvasRenderable?,
        bottom: AnyCanvasRenderable?,
        in canvas: inout Canvas
    ) {
        if var top {
            top.frame = topFrame
            top.render(in: &canvas)
        }
        if var bottom {
            bottom.frame = bottomFrame
            bottom.render(in: &canvas)
        }
        render(in: &canvas)
    }

    private var clampedDividerOffset: Int {
        clampDividerOffset(dividerOffset)
    }

    private func clampDividerOffset(_ offset: Int) -> Int {
        guard isClamped else {
            return min(max(0, offset), max(0, frame.height - dividerHeight))
        }
        let maximum = max(minTop, frame.height - dividerHeight - minBottom)
        return min(max(minTop, offset), maximum)
    }
}
