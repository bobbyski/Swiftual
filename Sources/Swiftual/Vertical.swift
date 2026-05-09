import Foundation

public protocol CanvasRenderable: Sendable {
    var frame: Rect { get set }
    func render(in canvas: inout Canvas)
}

extension Label: CanvasRenderable {}
extension Button: CanvasRenderable {}
extension Checkbox: CanvasRenderable {}

public struct AnyCanvasRenderable: CanvasRenderable {
    public var frame: Rect
    private let renderBody: @Sendable (inout Canvas, Rect) -> Void

    public init<Renderable: CanvasRenderable>(_ renderable: Renderable) {
        self.frame = renderable.frame
        self.renderBody = { canvas, frame in
            var copy = renderable
            copy.frame = frame
            copy.render(in: &canvas)
        }
    }

    public func render(in canvas: inout Canvas) {
        renderBody(&canvas, frame)
    }
}

public struct Vertical: CanvasRenderable {
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

        var y = frame.y
        for child in children {
            guard y < frame.y + frame.height else { return }
            var placed = child
            placed.frame = Rect(
                x: frame.x,
                y: y,
                width: min(frame.width, child.frame.width),
                height: min(child.frame.height, max(0, frame.y + frame.height - y))
            )
            placed.render(in: &canvas)
            y += child.frame.height + spacing
        }
    }
}
