import Foundation

public enum FlowAxis: Equatable, Sendable {
    case vertical
    case horizontal

    public var mainDimension: FlowDimension {
        switch self {
        case .vertical:
            .height
        case .horizontal:
            .width
        }
    }

    public var crossDimension: FlowDimension {
        switch self {
        case .vertical:
            .width
        case .horizontal:
            .height
        }
    }
}

public enum FlowDimension: Equatable, Sendable {
    case width
    case height
}

public enum LayoutLength: Equatable, Sendable {
    case cells(Int)
    case fraction(Double)
    case percent(Double)
    case containerWidth(Double)
    case containerHeight(Double)
    case viewportWidth(Double)
    case viewportHeight(Double)
    case auto
    case fill

    public var normalized: LayoutLength {
        switch self {
        case .cells(let value):
            .cells(max(0, value))
        case .fraction(let value):
            .fraction(max(0, value))
        case .percent(let value):
            .percent(max(0, value))
        case .containerWidth(let value):
            .containerWidth(max(0, value))
        case .containerHeight(let value):
            .containerHeight(max(0, value))
        case .viewportWidth(let value):
            .viewportWidth(max(0, value))
        case .viewportHeight(let value):
            .viewportHeight(max(0, value))
        case .auto:
            .auto
        case .fill:
            .fill
        }
    }
}

public struct FlowSpacing: Equatable, Sendable {
    public var main: Int

    public init(main: Int = 0) {
        self.main = max(0, main)
    }

    public static let none = FlowSpacing()
}

public struct BoxEdges: Equatable, Sendable {
    public var top: Int
    public var right: Int
    public var bottom: Int
    public var left: Int

    public init(top: Int, right: Int, bottom: Int, left: Int) {
        self.top = max(0, top)
        self.right = max(0, right)
        self.bottom = max(0, bottom)
        self.left = max(0, left)
    }

    public init(_ value: Int) {
        self.init(top: value, right: value, bottom: value, left: value)
    }

    public init(vertical: Int, horizontal: Int) {
        self.init(top: vertical, right: horizontal, bottom: vertical, left: horizontal)
    }

    public static let zero = BoxEdges(0)

    public var horizontal: Int {
        left + right
    }

    public var vertical: Int {
        top + bottom
    }

    public func inset(_ rect: Rect) -> Rect {
        Rect(
            x: rect.x + left,
            y: rect.y + top,
            width: max(0, rect.width - horizontal),
            height: max(0, rect.height - vertical)
        )
    }
}

public enum HorizontalAlignment: Equatable, Sendable {
    case left
    case center
    case right
    case stretch
}

public enum VerticalAlignment: Equatable, Sendable {
    case top
    case middle
    case bottom
    case stretch
}

public struct FlowAlignment: Equatable, Sendable {
    public var horizontal: HorizontalAlignment
    public var vertical: VerticalAlignment

    public init(
        horizontal: HorizontalAlignment = .stretch,
        vertical: VerticalAlignment = .top
    ) {
        self.horizontal = horizontal
        self.vertical = vertical
    }

    public static let fill = FlowAlignment(horizontal: .stretch, vertical: .stretch)
    public static let topLeading = FlowAlignment(horizontal: .left, vertical: .top)
    public static let center = FlowAlignment(horizontal: .center, vertical: .middle)
}

public enum OverflowPolicy: Equatable, Sendable {
    case visible
    case hidden
    case scroll
    case auto
}

public struct Overflow: Equatable, Sendable {
    public var x: OverflowPolicy
    public var y: OverflowPolicy

    public init(x: OverflowPolicy = .hidden, y: OverflowPolicy = .hidden) {
        self.x = x
        self.y = y
    }

    public static let visible = Overflow(x: .visible, y: .visible)
    public static let hidden = Overflow(x: .hidden, y: .hidden)
    public static let auto = Overflow(x: .auto, y: .auto)
}

public struct ScrollPolicy: Equatable, Sendable {
    public var showsHorizontalScrollbar: Bool
    public var showsVerticalScrollbar: Bool
    public var scrollsWithKeyboard: Bool
    public var scrollsWithMouseWheel: Bool
    public var scrollsWithThumbDrag: Bool

    public init(
        showsHorizontalScrollbar: Bool = false,
        showsVerticalScrollbar: Bool = false,
        scrollsWithKeyboard: Bool = false,
        scrollsWithMouseWheel: Bool = false,
        scrollsWithThumbDrag: Bool = false
    ) {
        self.showsHorizontalScrollbar = showsHorizontalScrollbar
        self.showsVerticalScrollbar = showsVerticalScrollbar
        self.scrollsWithKeyboard = scrollsWithKeyboard
        self.scrollsWithMouseWheel = scrollsWithMouseWheel
        self.scrollsWithThumbDrag = scrollsWithThumbDrag
    }

    public static let none = ScrollPolicy()

    public static let interactive = ScrollPolicy(
        showsHorizontalScrollbar: true,
        showsVerticalScrollbar: true,
        scrollsWithKeyboard: true,
        scrollsWithMouseWheel: true,
        scrollsWithThumbDrag: true
    )
}

public struct LayoutPreferences: Equatable, Sendable {
    public var width: LayoutLength
    public var height: LayoutLength
    public var minWidth: LayoutLength
    public var minHeight: LayoutLength
    public var maxWidth: LayoutLength?
    public var maxHeight: LayoutLength?
    public var margin: BoxEdges

    public init(
        width: LayoutLength = .auto,
        height: LayoutLength = .auto,
        minWidth: LayoutLength = .cells(0),
        minHeight: LayoutLength = .cells(0),
        maxWidth: LayoutLength? = nil,
        maxHeight: LayoutLength? = nil,
        margin: BoxEdges = .zero
    ) {
        self.width = width.normalized
        self.height = height.normalized
        self.minWidth = minWidth.normalized
        self.minHeight = minHeight.normalized
        self.maxWidth = maxWidth?.normalized
        self.maxHeight = maxHeight?.normalized
        self.margin = margin
    }

    public static let explicitFrame = LayoutPreferences()

    public var normalized: LayoutPreferences {
        LayoutPreferences(
            width: width,
            height: height,
            minWidth: minWidth,
            minHeight: minHeight,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            margin: margin
        )
    }
}

public struct IntrinsicSize: Equatable, Sendable {
    public var width: Int
    public var height: Int

    public init(width: Int, height: Int) {
        self.width = max(0, width)
        self.height = max(0, height)
    }

    public static let zero = IntrinsicSize(width: 0, height: 0)
}
