import Foundation

public protocol CanvasRenderable: Sendable {
    var frame: Rect { get set }
    func render(in canvas: inout Canvas)
}

extension Label: CanvasRenderable {}
extension Button: CanvasRenderable {}

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
    public var alignment: FlowAlignment
    public var fillStyle: TerminalStyle?
    public var border: FlowBorder
    public var borderTitle: String?
    public var borderSubtitle: String?
    public var children: [AnyCanvasRenderable]

    public init(
        frame: Rect,
        spacing: Int = 0,
        alignment: FlowAlignment = .topLeading,
        fillStyle: TerminalStyle? = nil,
        border: FlowBorder = .none,
        borderTitle: String? = nil,
        borderSubtitle: String? = nil,
        children: [AnyCanvasRenderable]
    ) {
        self.frame = frame
        self.spacing = max(0, spacing)
        self.alignment = alignment
        self.fillStyle = fillStyle
        self.border = border
        self.borderTitle = borderTitle
        self.borderSubtitle = borderSubtitle
        self.children = children
    }

    public func render(in canvas: inout Canvas) {
        FlowContainer(
            frame: frame,
            axis: .vertical,
            spacing: FlowSpacing(main: spacing),
            alignment: alignment,
            fillStyle: fillStyle,
            border: border,
            borderTitle: borderTitle,
            borderSubtitle: borderSubtitle,
            children: children.map { FlowChild($0) }
        ).render(in: &canvas)
    }
}
