import Foundation

public struct ProgressBar: CanvasRenderable, Equatable, Sendable {
    public var frame: Rect
    public var value: Double?
    public var range: ClosedRange<Double>
    public var label: String?
    public var showPercentage: Bool
    public var pulseOffset: Int
    public var trackStyle: TerminalStyle
    public var completedStyle: TerminalStyle
    public var pulseStyle: TerminalStyle
    public var textStyle: TerminalStyle

    public init(
        frame: Rect,
        value: Double? = 0,
        range: ClosedRange<Double> = 0...1,
        label: String? = nil,
        showPercentage: Bool = true,
        pulseOffset: Int = 0,
        trackStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        completedStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .green, bold: true),
        pulseStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .cyan, bold: true),
        textStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true)
    ) {
        self.frame = frame
        self.value = value
        self.range = range
        self.label = label
        self.showPercentage = showPercentage
        self.pulseOffset = pulseOffset
        self.trackStyle = trackStyle
        self.completedStyle = completedStyle
        self.pulseStyle = pulseStyle
        self.textStyle = textStyle
    }

    public var fractionComplete: Double? {
        guard let value else { return nil }
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return value >= range.upperBound ? 1 : 0 }
        return min(1, max(0, (value - range.lowerBound) / span))
    }

    public func render(in canvas: inout Canvas) {
        guard frame.width > 0, frame.height > 0 else { return }
        canvas.fill(rect: frame, style: trackStyle)

        if let fractionComplete {
            let completedWidth = Int((Double(frame.width) * fractionComplete).rounded(.down))
            if completedWidth > 0 {
                canvas.fill(rect: Rect(x: frame.x, y: frame.y, width: completedWidth, height: frame.height), style: completedStyle)
            }
        } else {
            renderPulse(in: &canvas)
        }

        if let text = displayText {
            let visible = String(text.prefix(frame.width))
            let textX = frame.x + max(0, (frame.width - visible.count) / 2)
            let textY = frame.y + max(0, frame.height / 2)
            canvas.drawText(visible, at: Point(x: textX, y: textY), style: textStyle)
        }
    }

    private var displayText: String? {
        var parts: [String] = []
        if let label, !label.isEmpty {
            parts.append(label)
        }
        if showPercentage, let fractionComplete {
            parts.append("\(Int((fractionComplete * 100).rounded()))%")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    private func renderPulse(in canvas: inout Canvas) {
        let pulseWidth = min(frame.width, max(1, frame.width / 4))
        let travel = max(1, frame.width + pulseWidth)
        let normalizedOffset = ((pulseOffset % travel) + travel) % travel
        let start = frame.x + normalizedOffset - pulseWidth
        let end = start + pulseWidth
        let visibleStart = max(frame.x, start)
        let visibleEnd = min(frame.x + frame.width, end)
        guard visibleEnd > visibleStart else { return }
        canvas.fill(
            rect: Rect(x: visibleStart, y: frame.y, width: visibleEnd - visibleStart, height: frame.height),
            style: pulseStyle
        )
    }
}
