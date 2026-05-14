import Foundation

public enum BorderLabelAlignment: Equatable, Sendable {
    case left
    case center
    case right
}

public struct BorderCharacters: Equatable, Sendable {
    public var topLeft: Character
    public var topRight: Character
    public var bottomLeft: Character
    public var bottomRight: Character
    public var horizontal: Character
    public var vertical: Character

    public init(
        topLeft: Character,
        topRight: Character,
        bottomLeft: Character,
        bottomRight: Character,
        horizontal: Character,
        vertical: Character
    ) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
        self.horizontal = horizontal
        self.vertical = vertical
    }

    public static let single = BorderCharacters(
        topLeft: "┌",
        topRight: "┐",
        bottomLeft: "└",
        bottomRight: "┘",
        horizontal: "─",
        vertical: "│"
    )

    public static let double = BorderCharacters(
        topLeft: "╔",
        topRight: "╗",
        bottomLeft: "╚",
        bottomRight: "╝",
        horizontal: "═",
        vertical: "║"
    )

    public static let heavy = BorderCharacters(
        topLeft: "┏",
        topRight: "┓",
        bottomLeft: "┗",
        bottomRight: "┛",
        horizontal: "━",
        vertical: "┃"
    )

    public static let dashed = BorderCharacters(
        topLeft: "┌",
        topRight: "┐",
        bottomLeft: "└",
        bottomRight: "┘",
        horizontal: "╌",
        vertical: "╎"
    )

    public static let rounded = BorderCharacters(
        topLeft: "╭",
        topRight: "╮",
        bottomLeft: "╰",
        bottomRight: "╯",
        horizontal: "─",
        vertical: "│"
    )

    public static let ascii = BorderCharacters(
        topLeft: "+",
        topRight: "+",
        bottomLeft: "+",
        bottomRight: "+",
        horizontal: "-",
        vertical: "|"
    )

    public static let blank = BorderCharacters(
        topLeft: " ",
        topRight: " ",
        bottomLeft: " ",
        bottomRight: " ",
        horizontal: " ",
        vertical: " "
    )
}

public struct FlowBorder: Equatable, Sendable {
    public var isVisible: Bool
    public var characters: BorderCharacters
    public var style: TerminalStyle
    public var titleStyle: TerminalStyle
    public var subtitleStyle: TerminalStyle
    public var titleAlignment: BorderLabelAlignment
    public var subtitleAlignment: BorderLabelAlignment

    public init(
        isVisible: Bool = false,
        characters: BorderCharacters = .single,
        style: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        titleStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black, bold: true),
        subtitleStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black, bold: true),
        titleAlignment: BorderLabelAlignment = .left,
        subtitleAlignment: BorderLabelAlignment = .right
    ) {
        self.isVisible = isVisible
        self.characters = characters
        self.style = style
        self.titleStyle = titleStyle
        self.subtitleStyle = subtitleStyle
        self.titleAlignment = titleAlignment
        self.subtitleAlignment = subtitleAlignment
    }

    public static let none = FlowBorder()

    public static func single(
        style: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        titleStyle: TerminalStyle? = nil,
        subtitleStyle: TerminalStyle? = nil,
        titleAlignment: BorderLabelAlignment = .left,
        subtitleAlignment: BorderLabelAlignment = .right
    ) -> FlowBorder {
        FlowBorder(
            isVisible: true,
            style: style,
            titleStyle: titleStyle ?? style,
            subtitleStyle: subtitleStyle ?? titleStyle ?? style,
            titleAlignment: titleAlignment,
            subtitleAlignment: subtitleAlignment
        )
    }

    public static func double(
        style: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        titleStyle: TerminalStyle? = nil,
        subtitleStyle: TerminalStyle? = nil,
        titleAlignment: BorderLabelAlignment = .left,
        subtitleAlignment: BorderLabelAlignment = .right
    ) -> FlowBorder {
        FlowBorder(
            isVisible: true,
            characters: .double,
            style: style,
            titleStyle: titleStyle ?? style,
            subtitleStyle: subtitleStyle ?? titleStyle ?? style,
            titleAlignment: titleAlignment,
            subtitleAlignment: subtitleAlignment
        )
    }

    public static func heavy(
        style: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        titleStyle: TerminalStyle? = nil,
        subtitleStyle: TerminalStyle? = nil,
        titleAlignment: BorderLabelAlignment = .left,
        subtitleAlignment: BorderLabelAlignment = .right
    ) -> FlowBorder {
        FlowBorder(
            isVisible: true,
            characters: .heavy,
            style: style,
            titleStyle: titleStyle ?? style,
            subtitleStyle: subtitleStyle ?? titleStyle ?? style,
            titleAlignment: titleAlignment,
            subtitleAlignment: subtitleAlignment
        )
    }

    public static func dashed(
        style: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        titleStyle: TerminalStyle? = nil,
        subtitleStyle: TerminalStyle? = nil,
        titleAlignment: BorderLabelAlignment = .left,
        subtitleAlignment: BorderLabelAlignment = .right
    ) -> FlowBorder {
        FlowBorder(
            isVisible: true,
            characters: .dashed,
            style: style,
            titleStyle: titleStyle ?? style,
            subtitleStyle: subtitleStyle ?? titleStyle ?? style,
            titleAlignment: titleAlignment,
            subtitleAlignment: subtitleAlignment
        )
    }

    public static func rounded(
        style: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        titleStyle: TerminalStyle? = nil,
        subtitleStyle: TerminalStyle? = nil,
        titleAlignment: BorderLabelAlignment = .left,
        subtitleAlignment: BorderLabelAlignment = .right
    ) -> FlowBorder {
        FlowBorder(
            isVisible: true,
            characters: .rounded,
            style: style,
            titleStyle: titleStyle ?? style,
            subtitleStyle: subtitleStyle ?? titleStyle ?? style,
            titleAlignment: titleAlignment,
            subtitleAlignment: subtitleAlignment
        )
    }

    public static func ascii(
        style: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        titleStyle: TerminalStyle? = nil,
        subtitleStyle: TerminalStyle? = nil,
        titleAlignment: BorderLabelAlignment = .left,
        subtitleAlignment: BorderLabelAlignment = .right
    ) -> FlowBorder {
        FlowBorder(
            isVisible: true,
            characters: .ascii,
            style: style,
            titleStyle: titleStyle ?? style,
            subtitleStyle: subtitleStyle ?? titleStyle ?? style,
            titleAlignment: titleAlignment,
            subtitleAlignment: subtitleAlignment
        )
    }

    public static func blank(
        style: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        titleStyle: TerminalStyle? = nil,
        subtitleStyle: TerminalStyle? = nil,
        titleAlignment: BorderLabelAlignment = .left,
        subtitleAlignment: BorderLabelAlignment = .right
    ) -> FlowBorder {
        FlowBorder(
            isVisible: true,
            characters: .blank,
            style: style,
            titleStyle: titleStyle ?? style,
            subtitleStyle: subtitleStyle ?? titleStyle ?? style,
            titleAlignment: titleAlignment,
            subtitleAlignment: subtitleAlignment
        )
    }
}

public struct FlowChild: Sendable {
    public var renderable: AnyCanvasRenderable
    public var preferences: LayoutPreferences
    public var reservesLayout: Bool
    public var shouldRender: Bool

    public init(
        _ renderable: AnyCanvasRenderable,
        preferences: LayoutPreferences? = nil,
        reservesLayout: Bool = true,
        shouldRender: Bool = true
    ) {
        self.renderable = renderable
        self.preferences = preferences ?? LayoutPreferences(
            width: .auto,
            height: .auto,
            minWidth: .cells(0),
            minHeight: .cells(0)
        )
        self.reservesLayout = reservesLayout
        self.shouldRender = shouldRender
    }

    public init<Renderable: CanvasRenderable>(
        _ renderable: Renderable,
        preferences: LayoutPreferences? = nil,
        reservesLayout: Bool = true,
        shouldRender: Bool = true
    ) {
        self.init(
            AnyCanvasRenderable(renderable),
            preferences: preferences,
            reservesLayout: reservesLayout,
            shouldRender: shouldRender
        )
    }

    public var intrinsicSize: IntrinsicSize {
        IntrinsicSize(width: renderable.frame.width, height: renderable.frame.height)
    }
}

public struct FlowContainer: CanvasRenderable {
    public var frame: Rect
    public var axis: FlowAxis
    public var spacing: FlowSpacing
    public var padding: BoxEdges
    public var alignment: FlowAlignment
    public var overflow: Overflow
    public var scrollPolicy: ScrollPolicy
    public var scrollOffset: Point
    public var fillStyle: TerminalStyle?
    public var border: FlowBorder
    public var borderTitle: String?
    public var borderSubtitle: String?
    public var viewportSize: TerminalSize?
    public var children: [FlowChild]

    public init(
        frame: Rect,
        axis: FlowAxis,
        spacing: FlowSpacing = .none,
        padding: BoxEdges = .zero,
        alignment: FlowAlignment = FlowAlignment(),
        overflow: Overflow = .hidden,
        scrollPolicy: ScrollPolicy = .none,
        scrollOffset: Point = Point(x: 0, y: 0),
        fillStyle: TerminalStyle? = nil,
        border: FlowBorder = .none,
        borderTitle: String? = nil,
        borderSubtitle: String? = nil,
        viewportSize: TerminalSize? = nil,
        children: [FlowChild]
    ) {
        self.frame = frame
        self.axis = axis
        self.spacing = spacing
        self.padding = padding
        self.alignment = alignment
        self.overflow = overflow
        self.scrollPolicy = scrollPolicy
        self.scrollOffset = Point(x: max(0, scrollOffset.x), y: max(0, scrollOffset.y))
        self.fillStyle = fillStyle
        self.border = border
        self.borderTitle = borderTitle
        self.borderSubtitle = borderSubtitle
        self.viewportSize = viewportSize
        self.children = children
    }

    public var contentFrame: Rect {
        padding.inset(chromeFrame)
    }

    public var chromeFrame: Rect {
        guard border.isVisible else { return frame }
        return Rect(x: frame.x + 1, y: frame.y + 1, width: max(0, frame.width - 2), height: max(0, frame.height - 2))
    }

    public func laidOutChildren() -> [Rect] {
        let content = contentFrame
        guard !children.isEmpty, content.width > 0, content.height > 0 else { return [] }

        let activeIndices = children.indices.filter { children[$0].reservesLayout }
        guard !activeIndices.isEmpty else {
            return Array(repeating: Rect(x: content.x, y: content.y, width: 0, height: 0), count: children.count)
        }

        let mainAvailable = axis == .vertical ? content.height : content.width
        let crossAvailable = axis == .vertical ? content.width : content.height
        let totalSpacing = max(0, activeIndices.count - 1) * spacing.main
        let totalMainMargin = activeIndices.reduce(0) { $0 + mainMargin(for: children[$1].preferences.margin) }
        let mainContentAvailable = max(0, mainAvailable - totalSpacing - totalMainMargin)
        let intrinsic = children.map(\.intrinsicSize)
        let mainLengths = resolveMainLengths(available: mainContentAvailable, intrinsic: intrinsic, indices: activeIndices)

        var frames = Array(repeating: Rect(x: content.x, y: content.y, width: 0, height: 0), count: children.count)
        var cursor = axis == .vertical ? content.y - scrollOffset.y : content.x - scrollOffset.x

        for index in activeIndices {
            let child = children[index]
            let margin = child.preferences.margin
            let crossMargin = crossMargin(for: margin)
            let childCrossAvailable = max(0, crossAvailable - crossMargin)
            let childMain = mainLengths[index]
            let childCross = resolveCrossLength(child: child, intrinsic: intrinsic[index], available: childCrossAvailable)
            let crossOrigin = crossStart(for: childCross, available: childCrossAvailable, content: content, margin: margin)

            cursor += mainStartMargin(for: margin)

            let rect: Rect
            if axis == .vertical {
                rect = Rect(x: crossOrigin, y: cursor, width: childCross, height: childMain)
            } else {
                rect = Rect(x: cursor, y: crossOrigin, width: childMain, height: childCross)
            }
            frames[index] = rect
            cursor += childMain + mainEndMargin(for: margin) + spacing.main
        }

        return frames
    }

    public func render(in canvas: inout Canvas) {
        if let fillStyle {
            canvas.fill(rect: frame, style: fillStyle)
        }
        renderBorder(in: &canvas)

        let frames = laidOutChildren()
        for index in children.indices {
            guard frames.indices.contains(index) else { break }
            guard children[index].reservesLayout, children[index].shouldRender else { continue }
            let frame = clip(frames[index], canvasSize: canvas.size)
            guard frame.width > 0, frame.height > 0 else { continue }
            var child = children[index].renderable
            child.frame = frame
            child.render(in: &canvas)
        }
    }

    private func resolveMainLengths(available: Int, intrinsic: [IntrinsicSize], indices: [Int]) -> [Int] {
        var lengths = Array(repeating: 0, count: children.count)
        var remaining = available
        var fractionWeight = 0.0
        var fillCount = 0
        var fractionIndices: [Int] = []
        var fillIndices: [Int] = []

        for index in indices {
            let child = children[index]
            let length = mainLength(for: child.preferences)
            switch length {
            case .cells(let value):
                lengths[index] = clampMain(value, preferences: child.preferences, intrinsic: intrinsic[index], available: available)
                remaining -= lengths[index]
            case .percent, .containerWidth, .containerHeight, .viewportWidth, .viewportHeight:
                lengths[index] = clampMain(resolvedLength(length, intrinsic: intrinsic[index], available: available, container: contentFrame), preferences: child.preferences, intrinsic: intrinsic[index], available: available)
                remaining -= lengths[index]
            case .auto:
                let value = axis == .vertical ? intrinsic[index].height : intrinsic[index].width
                lengths[index] = clampMain(value, preferences: child.preferences, intrinsic: intrinsic[index], available: available)
                remaining -= lengths[index]
            case .fraction(let value):
                fractionWeight += max(0, value)
                fractionIndices.append(index)
            case .fill:
                fillCount += 1
                fillIndices.append(index)
            }
        }

        remaining = max(0, remaining)
        if fractionWeight > 0 {
            var assigned = 0
            for index in fractionIndices {
                guard case .fraction(let weight) = mainLength(for: children[index].preferences) else { continue }
                let share = Int((Double(remaining) * max(0, weight) / fractionWeight).rounded(.down))
                lengths[index] = clampMain(share, preferences: children[index].preferences, intrinsic: intrinsic[index], available: available)
                assigned += lengths[index]
            }
            distributeRemainder(max(0, remaining - assigned), among: fractionIndices, lengths: &lengths)
        } else if fillCount > 0 {
            let share = remaining / fillCount
            let remainder = remaining % fillCount
            for (offset, index) in fillIndices.enumerated() {
                lengths[index] = clampMain(share + (offset < remainder ? 1 : 0), preferences: children[index].preferences, intrinsic: intrinsic[index], available: available)
            }
        }

        return lengths
    }

    private func distributeRemainder(_ remainder: Int, among indices: [Int], lengths: inout [Int]) {
        guard remainder > 0, !indices.isEmpty else { return }
        for offset in 0..<remainder {
            let index = indices[offset % indices.count]
            lengths[index] += 1
        }
    }

    private func resolveCrossLength(child: FlowChild, intrinsic: IntrinsicSize, available: Int) -> Int {
        let preferences = child.preferences
        let length = crossLength(for: preferences)
        let raw: Int
        switch length {
        case .cells(let value):
            raw = value
        case .percent(let value):
            raw = Int((Double(available) * value).rounded(.down))
        case .containerWidth(let value):
            raw = Int((Double(contentFrame.width) * value).rounded(.down))
        case .containerHeight(let value):
            raw = Int((Double(contentFrame.height) * value).rounded(.down))
        case .viewportWidth(let value):
            raw = Int((Double(viewportSize?.columns ?? frame.width) * value).rounded(.down))
        case .viewportHeight(let value):
            raw = Int((Double(viewportSize?.rows ?? frame.height) * value).rounded(.down))
        case .auto:
            raw = axis == .vertical ? intrinsic.width : intrinsic.height
        case .fraction, .fill:
            raw = available
        }
        let resolved = clampCross(raw, preferences: preferences, intrinsic: intrinsic, available: available)
        if (axis == .vertical && overflow.x == .visible) || (axis == .horizontal && overflow.y == .visible) {
            return resolved
        }
        return min(available, resolved)
    }

    private func crossStart(for length: Int, available: Int, content: Rect, margin: BoxEdges) -> Int {
        let extra = max(0, available - length)
        if axis == .vertical {
            let start = content.x + margin.left
            switch alignment.horizontal {
            case .left, .stretch:
                return start
            case .center:
                return start + extra / 2
            case .right:
                return start + extra
            }
        }
        let start = content.y + margin.top
        switch alignment.vertical {
        case .top, .stretch:
            return start
        case .middle:
            return start + extra / 2
        case .bottom:
            return start + extra
        }
    }

    private func mainMargin(for margin: BoxEdges) -> Int {
        mainStartMargin(for: margin) + mainEndMargin(for: margin)
    }

    private func mainStartMargin(for margin: BoxEdges) -> Int {
        axis == .vertical ? margin.top : margin.left
    }

    private func mainEndMargin(for margin: BoxEdges) -> Int {
        axis == .vertical ? margin.bottom : margin.right
    }

    private func crossMargin(for margin: BoxEdges) -> Int {
        axis == .vertical ? margin.horizontal : margin.vertical
    }

    private func clip(_ rect: Rect, canvasSize: TerminalSize) -> Rect {
        let clipFrame = contentFrame
        let canvasFrame = Rect(x: 0, y: 0, width: canvasSize.columns, height: canvasSize.rows)
        let minX = overflow.x == .visible ? canvasFrame.x : clipFrame.x
        let minY = overflow.y == .visible ? canvasFrame.y : clipFrame.y
        let limitX = overflow.x == .visible ? canvasFrame.x + canvasFrame.width : clipFrame.x + clipFrame.width
        let limitY = overflow.y == .visible ? canvasFrame.y + canvasFrame.height : clipFrame.y + clipFrame.height
        let x = max(rect.x, minX)
        let y = max(rect.y, minY)
        let maxX = min(rect.x + rect.width, limitX)
        let maxY = min(rect.y + rect.height, limitY)
        return Rect(x: x, y: y, width: max(0, maxX - x), height: max(0, maxY - y))
    }

    private func mainLength(for preferences: LayoutPreferences) -> LayoutLength {
        axis == .vertical ? preferences.height : preferences.width
    }

    private func crossLength(for preferences: LayoutPreferences) -> LayoutLength {
        axis == .vertical ? preferences.width : preferences.height
    }

    private func resolvedLength(_ length: LayoutLength, intrinsic: IntrinsicSize, available: Int, container: Rect) -> Int {
        switch length {
        case .cells(let value):
            return value
        case .percent(let value):
            return Int((Double(available) * value).rounded(.down))
        case .containerWidth(let value):
            return Int((Double(container.width) * value).rounded(.down))
        case .containerHeight(let value):
            return Int((Double(container.height) * value).rounded(.down))
        case .viewportWidth(let value):
            return Int((Double(viewportSize?.columns ?? frame.width) * value).rounded(.down))
        case .viewportHeight(let value):
            return Int((Double(viewportSize?.rows ?? frame.height) * value).rounded(.down))
        case .auto:
            return axis == .vertical ? intrinsic.height : intrinsic.width
        case .fraction, .fill:
            return available
        }
    }

    private func clampMain(_ value: Int, preferences: LayoutPreferences, intrinsic: IntrinsicSize, available: Int) -> Int {
        let minimum = axis == .vertical
            ? resolvedLength(preferences.minHeight, intrinsic: intrinsic, available: available, container: contentFrame)
            : resolvedLength(preferences.minWidth, intrinsic: intrinsic, available: available, container: contentFrame)
        let maximum = axis == .vertical
            ? preferences.maxHeight.map { resolvedLength($0, intrinsic: intrinsic, available: available, container: contentFrame) }
            : preferences.maxWidth.map { resolvedLength($0, intrinsic: intrinsic, available: available, container: contentFrame) }
        return clamp(value, min: minimum, max: maximum)
    }

    private func clampCross(_ value: Int, preferences: LayoutPreferences, intrinsic: IntrinsicSize, available: Int) -> Int {
        let minimum = axis == .vertical
            ? resolvedLength(preferences.minWidth, intrinsic: intrinsic, available: available, container: contentFrame)
            : resolvedLength(preferences.minHeight, intrinsic: intrinsic, available: available, container: contentFrame)
        let maximum = axis == .vertical
            ? preferences.maxWidth.map { resolvedLength($0, intrinsic: intrinsic, available: available, container: contentFrame) }
            : preferences.maxHeight.map { resolvedLength($0, intrinsic: intrinsic, available: available, container: contentFrame) }
        return clamp(value, min: minimum, max: maximum)
    }

    private func clamp(_ value: Int, min minimum: Int, max maximum: Int?) -> Int {
        Swift.min(Swift.max(0, Swift.max(minimum, value)), maximum ?? Int.max)
    }

    private func renderBorder(in canvas: inout Canvas) {
        guard border.isVisible, frame.width > 1, frame.height > 1 else { return }
        let style = border.style
        let left = frame.x
        let right = frame.x + frame.width - 1
        let top = frame.y
        let bottom = frame.y + frame.height - 1
        let characters = border.characters

        canvas.drawText(String(characters.topLeft), at: Point(x: left, y: top), style: style)
        canvas.drawText(String(characters.topRight), at: Point(x: right, y: top), style: style)
        canvas.drawText(String(characters.bottomLeft), at: Point(x: left, y: bottom), style: style)
        canvas.drawText(String(characters.bottomRight), at: Point(x: right, y: bottom), style: style)

        if right > left + 1 {
            canvas.fill(rect: Rect(x: left + 1, y: top, width: right - left - 1, height: 1), style: style, character: characters.horizontal)
            canvas.fill(rect: Rect(x: left + 1, y: bottom, width: right - left - 1, height: 1), style: style, character: characters.horizontal)
        }
        if bottom > top + 1 {
            canvas.fill(rect: Rect(x: left, y: top + 1, width: 1, height: bottom - top - 1), style: style, character: characters.vertical)
            canvas.fill(rect: Rect(x: right, y: top + 1, width: 1, height: bottom - top - 1), style: style, character: characters.vertical)
        }

        renderBorderLabel(borderTitle, row: top, alignment: border.titleAlignment, style: border.titleStyle, in: &canvas)
        renderBorderLabel(borderSubtitle, row: bottom, alignment: border.subtitleAlignment, style: border.subtitleStyle, in: &canvas)
    }

    private func renderBorderLabel(
        _ text: String?,
        row: Int,
        alignment: BorderLabelAlignment,
        style: TerminalStyle,
        in canvas: inout Canvas
    ) {
        guard let text, !text.isEmpty, frame.width > 4 else { return }
        let available = max(0, frame.width - 4)
        let label = String((" \(text) ").prefix(available))
        let x: Int
        switch alignment {
        case .left:
            x = frame.x + 2
        case .center:
            x = frame.x + max(2, (frame.width - label.count) / 2)
        case .right:
            x = frame.x + max(2, frame.width - label.count - 2)
        }
        canvas.drawText(label, at: Point(x: x, y: row), style: style)
    }
}

public struct VerticalGroup: CanvasRenderable {
    public var container: FlowContainer

    public init(frame: Rect, spacing: Int = 0, fillStyle: TerminalStyle? = nil, border: FlowBorder = .none, borderTitle: String? = nil, borderSubtitle: String? = nil, children: [FlowChild]) {
        self.container = FlowContainer(frame: frame, axis: .vertical, spacing: FlowSpacing(main: spacing), alignment: .topLeading, fillStyle: fillStyle, border: border, borderTitle: borderTitle, borderSubtitle: borderSubtitle, children: children)
    }

    public var frame: Rect {
        get { container.frame }
        set { container.frame = newValue }
    }

    public func render(in canvas: inout Canvas) {
        container.render(in: &canvas)
    }
}

public struct HorizontalGroup: CanvasRenderable {
    public var container: FlowContainer

    public init(frame: Rect, spacing: Int = 0, fillStyle: TerminalStyle? = nil, border: FlowBorder = .none, borderTitle: String? = nil, borderSubtitle: String? = nil, children: [FlowChild]) {
        self.container = FlowContainer(frame: frame, axis: .horizontal, spacing: FlowSpacing(main: spacing), alignment: .topLeading, fillStyle: fillStyle, border: border, borderTitle: borderTitle, borderSubtitle: borderSubtitle, children: children)
    }

    public var frame: Rect {
        get { container.frame }
        set { container.frame = newValue }
    }

    public func render(in canvas: inout Canvas) {
        container.render(in: &canvas)
    }
}

public struct VerticalScroll: CanvasRenderable {
    public var container: FlowContainer

    public init(frame: Rect, spacing: Int = 0, scrollOffset: Int = 0, fillStyle: TerminalStyle? = nil, border: FlowBorder = .none, borderTitle: String? = nil, borderSubtitle: String? = nil, children: [FlowChild]) {
        self.container = FlowContainer(frame: frame, axis: .vertical, spacing: FlowSpacing(main: spacing), overflow: Overflow(x: .hidden, y: .auto), scrollPolicy: .interactive, scrollOffset: Point(x: 0, y: scrollOffset), fillStyle: fillStyle, border: border, borderTitle: borderTitle, borderSubtitle: borderSubtitle, children: children)
    }

    public var frame: Rect {
        get { container.frame }
        set { container.frame = newValue }
    }

    public func render(in canvas: inout Canvas) {
        container.render(in: &canvas)
    }
}

public struct HorizontalScroll: CanvasRenderable {
    public var container: FlowContainer

    public init(frame: Rect, spacing: Int = 0, scrollOffset: Int = 0, fillStyle: TerminalStyle? = nil, border: FlowBorder = .none, borderTitle: String? = nil, borderSubtitle: String? = nil, children: [FlowChild]) {
        self.container = FlowContainer(frame: frame, axis: .horizontal, spacing: FlowSpacing(main: spacing), overflow: Overflow(x: .auto, y: .hidden), scrollPolicy: .interactive, scrollOffset: Point(x: scrollOffset, y: 0), fillStyle: fillStyle, border: border, borderTitle: borderTitle, borderSubtitle: borderSubtitle, children: children)
    }

    public var frame: Rect {
        get { container.frame }
        set { container.frame = newValue }
    }

    public func render(in canvas: inout Canvas) {
        container.render(in: &canvas)
    }
}

public struct ScrollableContainer: CanvasRenderable {
    public var container: FlowContainer

    public init(frame: Rect, axis: FlowAxis = .vertical, spacing: Int = 0, scrollOffset: Point = Point(x: 0, y: 0), fillStyle: TerminalStyle? = nil, border: FlowBorder = .none, borderTitle: String? = nil, borderSubtitle: String? = nil, children: [FlowChild]) {
        self.container = FlowContainer(frame: frame, axis: axis, spacing: FlowSpacing(main: spacing), overflow: .auto, scrollPolicy: .interactive, scrollOffset: scrollOffset, fillStyle: fillStyle, border: border, borderTitle: borderTitle, borderSubtitle: borderSubtitle, children: children)
    }

    public var frame: Rect {
        get { container.frame }
        set { container.frame = newValue }
    }

    public func render(in canvas: inout Canvas) {
        container.render(in: &canvas)
    }
}

public struct Grid: CanvasRenderable {
    public var frame: Rect
    public var columns: Int
    public var rows: Int?
    public var gutter: FlowSpacing
    public var rowGutter: Int
    public var padding: BoxEdges
    public var fillStyle: TerminalStyle?
    public var border: FlowBorder
    public var borderTitle: String?
    public var borderSubtitle: String?
    public var children: [FlowChild]

    public init(
        frame: Rect,
        columns: Int,
        gutter: Int = 0,
        padding: BoxEdges = .zero,
        fillStyle: TerminalStyle? = nil,
        border: FlowBorder = .none,
        borderTitle: String? = nil,
        borderSubtitle: String? = nil,
        children: [FlowChild]
    ) {
        self.frame = frame
        self.columns = max(1, columns)
        self.rows = nil
        self.gutter = FlowSpacing(main: gutter)
        self.rowGutter = max(0, gutter)
        self.padding = padding
        self.fillStyle = fillStyle
        self.border = border
        self.borderTitle = borderTitle
        self.borderSubtitle = borderSubtitle
        self.children = children
    }

    public func render(in canvas: inout Canvas) {
        FlowContainer(frame: frame, axis: .vertical, fillStyle: fillStyle, border: border, borderTitle: borderTitle, borderSubtitle: borderSubtitle, children: []).render(in: &canvas)
        let chromeFrame = border.isVisible ? BoxEdges(1).inset(frame) : frame
        let content = padding.inset(chromeFrame)
        guard content.width > 0, content.height > 0 else { return }
        let totalGutter = max(0, columns - 1) * gutter.main
        let cellWidth = max(1, (content.width - totalGutter) / columns)
        let activeIndices = children.indices.filter { children[$0].reservesLayout }
        let cellHeight: Int
        if let rows {
            let totalRowGutter = max(0, rows - 1) * rowGutter
            cellHeight = max(1, (content.height - totalRowGutter) / rows)
        } else {
            cellHeight = activeIndices.map { children[$0].intrinsicSize.height }.max() ?? 1
        }
        for (placementIndex, childIndex) in activeIndices.enumerated() {
            let column = placementIndex % columns
            let row = placementIndex / columns
            if let rows, row >= rows { return }
            let x = content.x + column * (cellWidth + gutter.main)
            let y = content.y + row * (cellHeight + rowGutter)
            guard y < content.y + content.height else { return }
            guard children[childIndex].shouldRender else { continue }
            var child = children[childIndex].renderable
            child.frame = Rect(x: x, y: y, width: cellWidth, height: min(cellHeight, content.y + content.height - y))
            child.render(in: &canvas)
        }
    }
}
