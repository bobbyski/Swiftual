import Foundation

public struct Label: Equatable, Sendable {
    public var text: String
    public var frame: Rect
    public var style: TerminalStyle
    public var alignment: TextAlignment

    public init(
        _ text: String,
        frame: Rect,
        style: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .brightBlack),
        alignment: TextAlignment = .left
    ) {
        self.text = text
        self.frame = frame
        self.style = style
        self.alignment = alignment
    }

    public func render(in canvas: inout Canvas) {
        guard frame.width > 0, frame.height > 0 else { return }
        canvas.fill(rect: frame, style: style)

        let visible = String(text.prefix(frame.width))
        let x = switch alignment {
        case .left:
            frame.x
        case .center:
            frame.x + max(0, (frame.width - visible.count) / 2)
        case .right:
            frame.x + max(0, frame.width - visible.count)
        }

        canvas.drawText(visible, at: Point(x: x, y: frame.y), style: style)
    }
}

public enum TextAlignment: Equatable, Sendable {
    case left
    case center
    case right
}
