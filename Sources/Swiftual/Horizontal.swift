import Foundation

public struct Horizontal: CanvasRenderable {
    public var frame: Rect
    public var spacing: Int
    public var fillStyle: TerminalStyle?
    public var border: FlowBorder
    public var borderTitle: String?
    public var borderSubtitle: String?
    public var children: [AnyCanvasRenderable]

    public init(
        frame: Rect,
        spacing: Int = 0,
        fillStyle: TerminalStyle? = nil,
        border: FlowBorder = .none,
        borderTitle: String? = nil,
        borderSubtitle: String? = nil,
        children: [AnyCanvasRenderable]
    ) {
        self.frame = frame
        self.spacing = max(0, spacing)
        self.fillStyle = fillStyle
        self.border = border
        self.borderTitle = borderTitle
        self.borderSubtitle = borderSubtitle
        self.children = children
    }

    public func render(in canvas: inout Canvas) {
        FlowContainer(
            frame: frame,
            axis: .horizontal,
            spacing: FlowSpacing(main: spacing),
            alignment: .topLeading,
            fillStyle: fillStyle,
            border: border,
            borderTitle: borderTitle,
            borderSubtitle: borderSubtitle,
            children: children.map { FlowChild($0) }
        ).render(in: &canvas)
    }
}
