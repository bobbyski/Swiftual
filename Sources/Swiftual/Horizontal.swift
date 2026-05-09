import Foundation

public struct Horizontal: CanvasRenderable {
    public var frame: Rect
    public var spacing: Int
    public var fillStyle: TerminalStyle?
    public var children: [AnyCanvasRenderable]

    public init(
        frame: Rect,
        spacing: Int = 0,
        fillStyle: TerminalStyle? = nil,
        children: [AnyCanvasRenderable]
    ) {
        self.frame = frame
        self.spacing = max(0, spacing)
        self.fillStyle = fillStyle
        self.children = children
    }

    public func render(in canvas: inout Canvas) {
        if let fillStyle {
            canvas.fill(rect: frame, style: fillStyle)
        }

        var x = frame.x
        for child in children {
            guard x < frame.x + frame.width else { return }
            var placed = child
            placed.frame = Rect(
                x: x,
                y: frame.y,
                width: min(child.frame.width, max(0, frame.x + frame.width - x)),
                height: min(frame.height, child.frame.height)
            )
            placed.render(in: &canvas)
            x += child.frame.width + spacing
        }
    }
}
