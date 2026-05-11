import Foundation

public struct TCSSLayoutApplicator: Sendable {
    public init() {}

    public func apply(_ layout: TCSSLayoutStyle, to frame: Rect) -> Rect {
        var next = frame
        if let width = layout.width {
            next.width = max(1, width)
        }
        if let height = layout.height {
            next.height = max(1, height)
        }
        if let minWidth = layout.minWidth {
            next.width = max(next.width, resolved(minWidth, intrinsic: frame.width, frame: frame))
        }
        if let maxWidth = layout.maxWidth {
            next.width = min(next.width, max(1, resolvedDirectConstraint(maxWidth, intrinsic: frame.width, frame: frame)))
        }
        if let minHeight = layout.minHeight {
            next.height = max(next.height, resolvedDirectConstraint(minHeight, intrinsic: frame.height, frame: frame))
        }
        if let maxHeight = layout.maxHeight {
            next.height = min(next.height, max(1, resolvedDirectConstraint(maxHeight, intrinsic: frame.height, frame: frame)))
        }
        return next
    }

    public func layoutPreferences(from layout: TCSSLayoutStyle, fallback: LayoutPreferences) -> LayoutPreferences {
        LayoutPreferences(
            width: layout.widthLength ?? fallback.width,
            height: layout.heightLength ?? fallback.height,
            minWidth: layout.minWidth ?? fallback.minWidth,
            minHeight: layout.minHeight ?? fallback.minHeight,
            maxWidth: layout.maxWidth ?? fallback.maxWidth,
            maxHeight: layout.maxHeight ?? fallback.maxHeight,
            margin: layout.margin.map { BoxEdges(top: $0.top, right: $0.right, bottom: $0.bottom, left: $0.left) } ?? fallback.margin
        )
    }

    public func resolvedDirectConstraint(_ length: LayoutLength, intrinsic: Int, frame: Rect) -> Int {
        if case .cells = length {
            return resolved(length, intrinsic: intrinsic, frame: frame)
        }

        // Individual controls do not know their parent or viewport here.
        // Flow containers resolve non-cell constraints when they have that context.
        return intrinsic
    }

    public func resolved(_ length: LayoutLength, intrinsic: Int, frame: Rect) -> Int {
        switch length {
        case .cells(let value):
            return value
        case .fraction, .fill:
            return intrinsic
        case .percent(let value):
            return Int((Double(intrinsic) * value).rounded(.down))
        case .containerWidth(let value), .viewportWidth(let value):
            return Int((Double(frame.width) * value).rounded(.down))
        case .containerHeight(let value), .viewportHeight(let value):
            return Int((Double(frame.height) * value).rounded(.down))
        case .auto:
            return intrinsic
        }
    }
}

public struct TCSSButtonApplicator: TCSSStyleApplying {
    public var focusedStyle: TCSSStyle
    public var disabledStyle: TCSSStyle
    public var layoutApplicator: TCSSLayoutApplicator

    public init(
        focusedStyle: TCSSStyle = TCSSStyle(),
        disabledStyle: TCSSStyle = TCSSStyle(),
        layoutApplicator: TCSSLayoutApplicator = TCSSLayoutApplicator()
    ) {
        self.focusedStyle = focusedStyle
        self.disabledStyle = disabledStyle
        self.layoutApplicator = layoutApplicator
    }

    public func apply(_ style: TCSSStyle, to target: inout Button) {
        target.style = style.terminalStyle.applied(to: target.style)
        target.focusedStyle = focusedStyle.terminalStyle.applied(to: target.focusedStyle)
        target.disabledStyle = disabledStyle.terminalStyle.applied(to: target.disabledStyle)
        target.frame = layoutApplicator.apply(style.layout, to: target.frame)
    }
}

public struct TCSSLabelApplicator: TCSSStyleApplying {
    public var layoutApplicator: TCSSLayoutApplicator

    public init(layoutApplicator: TCSSLayoutApplicator = TCSSLayoutApplicator()) {
        self.layoutApplicator = layoutApplicator
    }

    public func apply(_ style: TCSSStyle, to target: inout Label) {
        target.style = style.terminalStyle.applied(to: target.style)
        target.frame = layoutApplicator.apply(style.layout, to: target.frame)
        if let textAlign = style.layout.textAlign {
            target.alignment = textAlignment(from: textAlign)
        }
    }

    private func textAlignment(from alignment: TCSSTextAlign) -> TextAlignment {
        switch alignment {
        case .left:
            .left
        case .center:
            .center
        case .right:
            .right
        }
    }
}

public struct TCSSProgressBarApplicator: TCSSStyleApplying {
    public var completeStyle: TCSSStyle
    public var pulseStyle: TCSSStyle
    public var textStyle: TCSSStyle
    public var layoutApplicator: TCSSLayoutApplicator

    public init(
        completeStyle: TCSSStyle = TCSSStyle(),
        pulseStyle: TCSSStyle = TCSSStyle(),
        textStyle: TCSSStyle = TCSSStyle(),
        layoutApplicator: TCSSLayoutApplicator = TCSSLayoutApplicator()
    ) {
        self.completeStyle = completeStyle
        self.pulseStyle = pulseStyle
        self.textStyle = textStyle
        self.layoutApplicator = layoutApplicator
    }

    public func apply(_ style: TCSSStyle, to target: inout ProgressBar) {
        target.trackStyle = style.terminalStyle.applied(to: target.trackStyle)
        target.completedStyle = completeStyle.terminalStyle.applied(to: target.completedStyle)
        target.pulseStyle = pulseStyle.terminalStyle.applied(to: target.pulseStyle)
        target.textStyle = textStyle.terminalStyle.applied(to: target.textStyle)
        target.frame = layoutApplicator.apply(style.layout, to: target.frame)
    }
}

public struct TCSSTextInputApplicator: TCSSStyleApplying {
    public var focusedStyle: TCSSStyle
    public var placeholderStyle: TCSSStyle
    public var cursorStyle: TCSSStyle
    public var layoutApplicator: TCSSLayoutApplicator

    public init(
        focusedStyle: TCSSStyle = TCSSStyle(),
        placeholderStyle: TCSSStyle = TCSSStyle(),
        cursorStyle: TCSSStyle = TCSSStyle(),
        layoutApplicator: TCSSLayoutApplicator = TCSSLayoutApplicator()
    ) {
        self.focusedStyle = focusedStyle
        self.placeholderStyle = placeholderStyle
        self.cursorStyle = cursorStyle
        self.layoutApplicator = layoutApplicator
    }

    public func apply(_ style: TCSSStyle, to target: inout TextInput) {
        target.style = style.terminalStyle.applied(to: target.style)
        target.focusedStyle = focusedStyle.terminalStyle.applied(to: target.focusedStyle)
        target.placeholderStyle = placeholderStyle.terminalStyle.applied(to: target.placeholderStyle)
        target.cursorStyle = cursorStyle.terminalStyle.applied(to: target.cursorStyle)
        target.frame = layoutApplicator.apply(style.layout, to: target.frame)
    }
}

public struct TCSSCheckboxApplicator: TCSSStyleApplying {
    public var focusedStyle: TCSSStyle
    public var checkedStyle: TCSSStyle
    public var disabledStyle: TCSSStyle
    public var layoutApplicator: TCSSLayoutApplicator

    public init(
        focusedStyle: TCSSStyle = TCSSStyle(),
        checkedStyle: TCSSStyle = TCSSStyle(),
        disabledStyle: TCSSStyle = TCSSStyle(),
        layoutApplicator: TCSSLayoutApplicator = TCSSLayoutApplicator()
    ) {
        self.focusedStyle = focusedStyle
        self.checkedStyle = checkedStyle
        self.disabledStyle = disabledStyle
        self.layoutApplicator = layoutApplicator
    }

    public func apply(_ style: TCSSStyle, to target: inout Checkbox) {
        target.style = style.terminalStyle.applied(to: target.style)
        target.focusedStyle = focusedStyle.terminalStyle.applied(to: target.focusedStyle)
        target.checkedStyle = checkedStyle.terminalStyle.applied(to: target.checkedStyle)
        target.focusedCheckedStyle = checkedStyle.terminalStyle.applied(to: target.focusedCheckedStyle)
        target.focusedCheckedStyle = focusedStyle.terminalStyle.applied(to: target.focusedCheckedStyle)
        target.disabledStyle = disabledStyle.terminalStyle.applied(to: target.disabledStyle)
        target.frame = layoutApplicator.apply(style.layout, to: target.frame)
    }
}

public struct TCSSSwitchApplicator: TCSSStyleApplying {
    public var onStyle: TCSSStyle
    public var focusedStyle: TCSSStyle
    public var disabledStyle: TCSSStyle
    public var layoutApplicator: TCSSLayoutApplicator

    public init(
        onStyle: TCSSStyle = TCSSStyle(),
        focusedStyle: TCSSStyle = TCSSStyle(),
        disabledStyle: TCSSStyle = TCSSStyle(),
        layoutApplicator: TCSSLayoutApplicator = TCSSLayoutApplicator()
    ) {
        self.onStyle = onStyle
        self.focusedStyle = focusedStyle
        self.disabledStyle = disabledStyle
        self.layoutApplicator = layoutApplicator
    }

    public func apply(_ style: TCSSStyle, to target: inout Switch) {
        target.offStyle = style.terminalStyle.applied(to: target.offStyle)
        target.onStyle = onStyle.terminalStyle.applied(to: target.onStyle)
        target.focusedOffStyle = focusedStyle.terminalStyle.applied(to: target.focusedOffStyle)
        target.focusedOnStyle = onStyle.terminalStyle.applied(to: target.focusedOnStyle)
        target.disabledStyle = disabledStyle.terminalStyle.applied(to: target.disabledStyle)
        target.frame = layoutApplicator.apply(style.layout, to: target.frame)
    }
}

public struct TCSSSelectApplicator: TCSSStyleApplying {
    public var focusedStyle: TCSSStyle
    public var openStyle: TCSSStyle
    public var optionStyle: TCSSStyle
    public var selectedOptionStyle: TCSSStyle
    public var disabledStyle: TCSSStyle
    public var layoutApplicator: TCSSLayoutApplicator

    public init(
        focusedStyle: TCSSStyle = TCSSStyle(),
        openStyle: TCSSStyle = TCSSStyle(),
        optionStyle: TCSSStyle = TCSSStyle(),
        selectedOptionStyle: TCSSStyle = TCSSStyle(),
        disabledStyle: TCSSStyle = TCSSStyle(),
        layoutApplicator: TCSSLayoutApplicator = TCSSLayoutApplicator()
    ) {
        self.focusedStyle = focusedStyle
        self.openStyle = openStyle
        self.optionStyle = optionStyle
        self.selectedOptionStyle = selectedOptionStyle
        self.disabledStyle = disabledStyle
        self.layoutApplicator = layoutApplicator
    }

    public func apply(_ style: TCSSStyle, to target: inout Select) {
        target.style = style.terminalStyle.applied(to: target.style)
        target.focusedStyle = focusedStyle.terminalStyle.applied(to: target.focusedStyle)
        target.openStyle = openStyle.terminalStyle.applied(to: target.openStyle)
        target.optionStyle = optionStyle.terminalStyle.applied(to: target.optionStyle)
        target.highlightedStyle = selectedOptionStyle.terminalStyle.applied(to: target.highlightedStyle)
        target.disabledStyle = disabledStyle.terminalStyle.applied(to: target.disabledStyle)
        target.frame = layoutApplicator.apply(style.layout, to: target.frame)
    }
}

public struct TCSSScrollViewApplicator: TCSSStyleApplying {
    public var contentStyle: TCSSStyle
    public var scrollbarStyle: TCSSStyle
    public var thumbStyle: TCSSStyle
    public var layoutApplicator: TCSSLayoutApplicator

    public init(
        contentStyle: TCSSStyle = TCSSStyle(),
        scrollbarStyle: TCSSStyle = TCSSStyle(),
        thumbStyle: TCSSStyle = TCSSStyle(),
        layoutApplicator: TCSSLayoutApplicator = TCSSLayoutApplicator()
    ) {
        self.contentStyle = contentStyle
        self.scrollbarStyle = scrollbarStyle
        self.thumbStyle = thumbStyle
        self.layoutApplicator = layoutApplicator
    }

    public func apply(_ style: TCSSStyle, to target: inout ScrollView) {
        target.fillStyle = style.terminalStyle.applied(to: target.fillStyle)
        target.contentStyle = contentStyle.terminalStyle.applied(to: target.contentStyle)
        target.scrollbarStyle = scrollbarStyle.terminalStyle.applied(to: target.scrollbarStyle)
        target.thumbStyle = thumbStyle.terminalStyle.applied(to: target.thumbStyle)
        if let width = scrollbarStyle.layout.width {
            target.scrollbarWidth = max(1, width)
        }
        target.frame = layoutApplicator.apply(style.layout, to: target.frame)
    }
}

public struct TCSSRichLogApplicator: TCSSStyleApplying {
    public var titleStyle: TCSSStyle
    public var layoutApplicator: TCSSLayoutApplicator

    public init(
        titleStyle: TCSSStyle = TCSSStyle(),
        layoutApplicator: TCSSLayoutApplicator = TCSSLayoutApplicator()
    ) {
        self.titleStyle = titleStyle
        self.layoutApplicator = layoutApplicator
    }

    public func apply(_ style: TCSSStyle, to target: inout RichLog) {
        target.fillStyle = style.terminalStyle.applied(to: target.fillStyle)
        target.titleStyle = titleStyle.terminalStyle.applied(to: target.titleStyle)
        target.frame = layoutApplicator.apply(style.layout, to: target.frame)
    }
}

public struct TCSSDataTableApplicator: TCSSStyleApplying {
    public var headerStyle: TCSSStyle
    public var rowStyle: TCSSStyle
    public var alternateRowStyle: TCSSStyle
    public var selectedRowStyle: TCSSStyle
    public var focusedSelectedRowStyle: TCSSStyle
    public var layoutApplicator: TCSSLayoutApplicator

    public init(
        headerStyle: TCSSStyle = TCSSStyle(),
        rowStyle: TCSSStyle = TCSSStyle(),
        alternateRowStyle: TCSSStyle = TCSSStyle(),
        selectedRowStyle: TCSSStyle = TCSSStyle(),
        focusedSelectedRowStyle: TCSSStyle = TCSSStyle(),
        layoutApplicator: TCSSLayoutApplicator = TCSSLayoutApplicator()
    ) {
        self.headerStyle = headerStyle
        self.rowStyle = rowStyle
        self.alternateRowStyle = alternateRowStyle
        self.selectedRowStyle = selectedRowStyle
        self.focusedSelectedRowStyle = focusedSelectedRowStyle
        self.layoutApplicator = layoutApplicator
    }

    public func apply(_ style: TCSSStyle, to target: inout DataTable) {
        target.rowStyle = style.terminalStyle.applied(to: target.rowStyle)
        target.rowStyle = rowStyle.terminalStyle.applied(to: target.rowStyle)
        target.headerStyle = headerStyle.terminalStyle.applied(to: target.headerStyle)
        target.alternateRowStyle = alternateRowStyle.terminalStyle.applied(to: target.alternateRowStyle)
        target.selectedRowStyle = selectedRowStyle.terminalStyle.applied(to: target.selectedRowStyle)
        target.focusedSelectedRowStyle = focusedSelectedRowStyle.terminalStyle.applied(to: target.focusedSelectedRowStyle)
        target.frame = layoutApplicator.apply(style.layout, to: target.frame)
    }
}

public struct TCSSTreeApplicator: TCSSStyleApplying {
    public var selectedStyle: TCSSStyle
    public var focusedSelectedStyle: TCSSStyle
    public var branchStyle: TCSSStyle
    public var scrollbarStyle: TCSSStyle
    public var thumbStyle: TCSSStyle
    public var layoutApplicator: TCSSLayoutApplicator

    public init(
        selectedStyle: TCSSStyle = TCSSStyle(),
        focusedSelectedStyle: TCSSStyle = TCSSStyle(),
        branchStyle: TCSSStyle = TCSSStyle(),
        scrollbarStyle: TCSSStyle = TCSSStyle(),
        thumbStyle: TCSSStyle = TCSSStyle(),
        layoutApplicator: TCSSLayoutApplicator = TCSSLayoutApplicator()
    ) {
        self.selectedStyle = selectedStyle
        self.focusedSelectedStyle = focusedSelectedStyle
        self.branchStyle = branchStyle
        self.scrollbarStyle = scrollbarStyle
        self.thumbStyle = thumbStyle
        self.layoutApplicator = layoutApplicator
    }

    public func apply(_ style: TCSSStyle, to target: inout Tree) {
        target.fillStyle = style.terminalStyle.applied(to: target.fillStyle)
        target.rowStyle = style.terminalStyle.applied(to: target.rowStyle)
        target.selectedStyle = selectedStyle.terminalStyle.applied(to: target.selectedStyle)
        target.focusedSelectedStyle = focusedSelectedStyle.terminalStyle.applied(to: target.focusedSelectedStyle)
        target.branchStyle = branchStyle.terminalStyle.applied(to: target.branchStyle)
        target.scrollbarStyle = scrollbarStyle.terminalStyle.applied(to: target.scrollbarStyle)
        target.thumbStyle = thumbStyle.terminalStyle.applied(to: target.thumbStyle)
        if let width = scrollbarStyle.layout.width {
            target.scrollbarWidth = max(1, width)
        }
        target.frame = layoutApplicator.apply(style.layout, to: target.frame)
    }
}

public struct TCSSModalApplicator: TCSSStyleApplying {
    public var overlayStyle: TCSSStyle
    public var titleStyle: TCSSStyle
    public var buttonStyle: TCSSStyle
    public var focusedButtonStyle: TCSSStyle
    public var disabledButtonStyle: TCSSStyle
    public var layoutApplicator: TCSSLayoutApplicator

    public init(
        overlayStyle: TCSSStyle = TCSSStyle(),
        titleStyle: TCSSStyle = TCSSStyle(),
        buttonStyle: TCSSStyle = TCSSStyle(),
        focusedButtonStyle: TCSSStyle = TCSSStyle(),
        disabledButtonStyle: TCSSStyle = TCSSStyle(),
        layoutApplicator: TCSSLayoutApplicator = TCSSLayoutApplicator()
    ) {
        self.overlayStyle = overlayStyle
        self.titleStyle = titleStyle
        self.buttonStyle = buttonStyle
        self.focusedButtonStyle = focusedButtonStyle
        self.disabledButtonStyle = disabledButtonStyle
        self.layoutApplicator = layoutApplicator
    }

    public func apply(_ style: TCSSStyle, to target: inout Modal) {
        target.panelStyle = style.terminalStyle.applied(to: target.panelStyle)
        target.overlayStyle = overlayStyle.terminalStyle.applied(to: target.overlayStyle)
        target.titleStyle = titleStyle.terminalStyle.applied(to: target.titleStyle)
        target.buttonStyle = buttonStyle.terminalStyle.applied(to: target.buttonStyle)
        target.focusedButtonStyle = focusedButtonStyle.terminalStyle.applied(to: target.focusedButtonStyle)
        target.disabledButtonStyle = disabledButtonStyle.terminalStyle.applied(to: target.disabledButtonStyle)
        target.frame = layoutApplicator.apply(style.layout, to: target.frame)
    }
}

public struct TCSSFlowContainerApplicator: TCSSStyleApplying {
    public var layoutApplicator: TCSSLayoutApplicator

    public init(layoutApplicator: TCSSLayoutApplicator = TCSSLayoutApplicator()) {
        self.layoutApplicator = layoutApplicator
    }

    public func apply(_ style: TCSSStyle, to target: inout FlowContainer) {
        if style.terminalStyle != TCSSTerminalStylePatch() {
            target.fillStyle = style.terminalStyle.applied(to: target.fillStyle ?? .plain)
        }
        if let spacing = style.layout.spacing {
            target.spacing = FlowSpacing(main: spacing)
        }
        if let padding = style.layout.padding {
            target.padding = BoxEdges(top: padding.top, right: padding.right, bottom: padding.bottom, left: padding.left)
        }
        target.frame = layoutApplicator.apply(style.layout, to: target.frame)
    }
}

public struct TCSSVerticalApplicator: TCSSStyleApplying {
    public var layoutApplicator: TCSSLayoutApplicator

    public init(layoutApplicator: TCSSLayoutApplicator = TCSSLayoutApplicator()) {
        self.layoutApplicator = layoutApplicator
    }

    public func apply(_ style: TCSSStyle, to target: inout Vertical) {
        if style.terminalStyle != TCSSTerminalStylePatch() {
            target.fillStyle = style.terminalStyle.applied(to: target.fillStyle ?? .plain)
        }
        if let spacing = style.layout.spacing {
            target.spacing = spacing
        }
        target.frame = layoutApplicator.apply(style.layout, to: target.frame)
    }
}

public struct TCSSHorizontalApplicator: TCSSStyleApplying {
    public var layoutApplicator: TCSSLayoutApplicator

    public init(layoutApplicator: TCSSLayoutApplicator = TCSSLayoutApplicator()) {
        self.layoutApplicator = layoutApplicator
    }

    public func apply(_ style: TCSSStyle, to target: inout Horizontal) {
        if style.terminalStyle != TCSSTerminalStylePatch() {
            target.fillStyle = style.terminalStyle.applied(to: target.fillStyle ?? .plain)
        }
        if let spacing = style.layout.spacing {
            target.spacing = spacing
        }
        target.frame = layoutApplicator.apply(style.layout, to: target.frame)
    }
}

public struct TCSSCommandPaletteApplicator: TCSSStyleApplying {
    public var titleStyle: TCSSStyle
    public var inputStyle: TCSSStyle
    public var itemStyle: TCSSStyle
    public var highlightedStyle: TCSSStyle
    public var disabledStyle: TCSSStyle
    public var layoutApplicator: TCSSLayoutApplicator

    public init(
        titleStyle: TCSSStyle = TCSSStyle(),
        inputStyle: TCSSStyle = TCSSStyle(),
        itemStyle: TCSSStyle = TCSSStyle(),
        highlightedStyle: TCSSStyle = TCSSStyle(),
        disabledStyle: TCSSStyle = TCSSStyle(),
        layoutApplicator: TCSSLayoutApplicator = TCSSLayoutApplicator()
    ) {
        self.titleStyle = titleStyle
        self.inputStyle = inputStyle
        self.itemStyle = itemStyle
        self.highlightedStyle = highlightedStyle
        self.disabledStyle = disabledStyle
        self.layoutApplicator = layoutApplicator
    }

    public func apply(_ style: TCSSStyle, to target: inout CommandPalette) {
        target.panelStyle = style.terminalStyle.applied(to: target.panelStyle)
        target.titleStyle = titleStyle.terminalStyle.applied(to: target.titleStyle)
        target.inputStyle = inputStyle.terminalStyle.applied(to: target.inputStyle)
        target.itemStyle = itemStyle.terminalStyle.applied(to: target.itemStyle)
        target.highlightedStyle = highlightedStyle.terminalStyle.applied(to: target.highlightedStyle)
        target.disabledStyle = disabledStyle.terminalStyle.applied(to: target.disabledStyle)
        target.frame = layoutApplicator.apply(style.layout, to: target.frame)
    }
}
