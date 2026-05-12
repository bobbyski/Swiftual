import Foundation

public struct TCSSStyleModel: Equatable, Sendable {
    public var rules: [TCSSStyleRule]
    public var diagnostics: [TCSSDiagnostic]

    public init(rules: [TCSSStyleRule] = [], diagnostics: [TCSSDiagnostic] = []) {
        self.rules = rules
        self.diagnostics = diagnostics
    }
}

public enum TCSSStylesheetSourceKind: String, Equatable, Sendable {
    case swiftDefaults
    case file
    case inline
    case generated
    case demo
}

public struct TCSSStylesheetSource: Equatable, Sendable {
    public var name: String
    public var source: String
    public var kind: TCSSStylesheetSourceKind
    public var isEnabled: Bool

    public init(
        name: String,
        source: String,
        kind: TCSSStylesheetSourceKind = .file,
        isEnabled: Bool = true
    ) {
        self.name = name
        self.source = source
        self.kind = kind
        self.isEnabled = isEnabled
    }
}

public protocol TCSSStylesheetProviding: Sendable {
    var tcssStylesheetSource: TCSSStylesheetSource { get }
}

extension TCSSStylesheetSource: TCSSStylesheetProviding {
    public var tcssStylesheetSource: TCSSStylesheetSource { self }
}

public struct TCSSParsedStylesheetSource: Equatable, Sendable {
    public var source: TCSSStylesheetSource
    public var stylesheet: TCSSStylesheet
    public var sourceIndex: Int

    public init(source: TCSSStylesheetSource, stylesheet: TCSSStylesheet, sourceIndex: Int) {
        self.source = source
        self.stylesheet = stylesheet
        self.sourceIndex = sourceIndex
    }
}

public struct TCSSStylesheetSourceSet: Equatable, Sendable {
    public var sources: [TCSSStylesheetSource]

    public init(sources: [TCSSStylesheetSource] = []) {
        self.sources = sources
    }

    public init<Provider: TCSSStylesheetProviding>(providers: [Provider]) {
        self.init(sources: providers.map(\.tcssStylesheetSource))
    }

    public var enabledSources: [TCSSStylesheetSource] {
        sources.filter(\.isEnabled)
    }

    public var enabledSourceNames: [String] {
        enabledSources.map(\.name)
    }

    public func parsed(using parser: TCSSParser = TCSSParser()) -> [TCSSParsedStylesheetSource] {
        enabledSources.enumerated().map { index, source in
            TCSSParsedStylesheetSource(
                source: source,
                stylesheet: parser.parse(source.source),
                sourceIndex: index
            )
        }
    }

    public func combinedSourcePreview(separator: String = "\n\n") -> String {
        enabledSources.map { source in
            """
            /* ---- \(source.name) ---- */
            \(source.source)
            """
        }.joined(separator: separator)
    }
}

public struct TCSSStyleRule: Equatable, Sendable {
    public var selectors: [TCSSSelector]
    public var style: TCSSStyle
    public var line: Int
    public var sourceName: String?
    public var sourceIndex: Int

    public init(
        selectors: [TCSSSelector],
        style: TCSSStyle,
        line: Int,
        sourceName: String? = nil,
        sourceIndex: Int = 0
    ) {
        self.selectors = selectors
        self.style = style
        self.line = line
        self.sourceName = sourceName
        self.sourceIndex = sourceIndex
    }
}

public struct TCSSStyle: Equatable, Sendable {
    public var terminalStyle: TCSSTerminalStylePatch
    public var layout: TCSSLayoutStyle

    public init(
        terminalStyle: TCSSTerminalStylePatch = TCSSTerminalStylePatch(),
        layout: TCSSLayoutStyle = TCSSLayoutStyle()
    ) {
        self.terminalStyle = terminalStyle
        self.layout = layout
    }
}

public struct TCSSTerminalStylePatch: Equatable, Sendable {
    public var foreground: TerminalColor?
    public var background: TerminalColor?
    public var bold: Bool?
    public var dim: Bool?
    public var italic: Bool?
    public var underline: Bool?
    public var strikethrough: Bool?
    public var inverse: Bool?
    public var blink: Bool?

    public init(
        foreground: TerminalColor? = nil,
        background: TerminalColor? = nil,
        bold: Bool? = nil,
        dim: Bool? = nil,
        italic: Bool? = nil,
        underline: Bool? = nil,
        strikethrough: Bool? = nil,
        inverse: Bool? = nil,
        blink: Bool? = nil
    ) {
        self.foreground = foreground
        self.background = background
        self.bold = bold
        self.dim = dim
        self.italic = italic
        self.underline = underline
        self.strikethrough = strikethrough
        self.inverse = inverse
        self.blink = blink
    }

    public func applied(to base: TerminalStyle) -> TerminalStyle {
        TerminalStyle(
            foreground: foreground ?? base.foreground,
            background: background ?? base.background,
            bold: bold ?? base.bold,
            dim: dim ?? base.dim,
            italic: italic ?? base.italic,
            underline: underline ?? base.underline,
            strikethrough: strikethrough ?? base.strikethrough,
            inverse: inverse ?? base.inverse,
            blink: blink ?? base.blink
        )
    }
}

public struct TCSSLayoutStyle: Equatable, Sendable {
    public var width: Int?
    public var height: Int?
    public var widthLength: LayoutLength?
    public var heightLength: LayoutLength?
    public var minWidth: LayoutLength?
    public var minHeight: LayoutLength?
    public var maxWidth: LayoutLength?
    public var maxHeight: LayoutLength?
    public var padding: TCSSBoxEdges?
    public var margin: TCSSBoxEdges?
    public var textAlign: TCSSTextAlign?
    public var overflow: Overflow?
    public var border: TCSSBorderKind?
    public var position: TCSSPosition?
    public var offset: Point?
    public var dividerWidth: Int?
    public var dividerHeight: Int?
    public var spacing: Int?

    public init(
        width: Int? = nil,
        height: Int? = nil,
        widthLength: LayoutLength? = nil,
        heightLength: LayoutLength? = nil,
        minWidth: LayoutLength? = nil,
        minHeight: LayoutLength? = nil,
        maxWidth: LayoutLength? = nil,
        maxHeight: LayoutLength? = nil,
        padding: TCSSBoxEdges? = nil,
        margin: TCSSBoxEdges? = nil,
        textAlign: TCSSTextAlign? = nil,
        overflow: Overflow? = nil,
        border: TCSSBorderKind? = nil,
        position: TCSSPosition? = nil,
        offset: Point? = nil,
        dividerWidth: Int? = nil,
        dividerHeight: Int? = nil,
        spacing: Int? = nil
    ) {
        self.width = width
        self.height = height
        self.widthLength = widthLength ?? width.map { .cells($0) }
        self.heightLength = heightLength ?? height.map { .cells($0) }
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.padding = padding
        self.margin = margin
        self.textAlign = textAlign
        self.overflow = overflow
        self.border = border
        self.position = position
        self.offset = offset
        self.dividerWidth = dividerWidth
        self.dividerHeight = dividerHeight
        self.spacing = spacing
    }
}

public struct TCSSBoxEdges: Equatable, Sendable {
    public var top: Int
    public var right: Int
    public var bottom: Int
    public var left: Int

    public init(top: Int, right: Int, bottom: Int, left: Int) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }

    public init(_ value: Int) {
        self.init(top: value, right: value, bottom: value, left: value)
    }
}

public enum TCSSTextAlign: String, Equatable, Sendable {
    case left
    case center
    case right
}

public enum TCSSPosition: String, Equatable, Sendable {
    case relative
    case absolute
}

public enum TCSSBorderKind: Equatable, Sendable {
    case none
    case single
    case double
    case dashed
    case rounded
    case ascii
    case vector

    public func flowBorder(style: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black)) -> FlowBorder {
        switch self {
        case .none, .vector:
            return .none
        case .single:
            return .single(style: style)
        case .double:
            return .double(style: style)
        case .dashed:
            return .dashed(style: style)
        case .rounded:
            return .rounded(style: style)
        case .ascii:
            return .ascii(style: style)
        }
    }
}

public struct TCSSStyleModelBuilder: Sendable {
    private let valueParser = TCSSValueParser()

    public init() {}

    public func build(from stylesheet: TCSSStylesheet) -> TCSSStyleModel {
        build(from: [stylesheet])
    }

    public func build(from stylesheets: [TCSSStylesheet]) -> TCSSStyleModel {
        build(
            from: stylesheets.enumerated().map { index, stylesheet in
                (stylesheet: stylesheet, source: Optional<TCSSStylesheetSource>.none, sourceIndex: index)
            }
        )
    }

    public func parse(_ source: String) -> TCSSStyleModel {
        build(from: TCSSParser().parse(source))
    }

    public func parse(_ sources: [TCSSStylesheetSource]) -> TCSSStyleModel {
        parse(TCSSStylesheetSourceSet(sources: sources))
    }

    public func parse(_ sourceSet: TCSSStylesheetSourceSet) -> TCSSStyleModel {
        build(from: sourceSet.parsed().map { parsed in
            (stylesheet: parsed.stylesheet, source: Optional(parsed.source), sourceIndex: parsed.sourceIndex)
        })
    }

    private func build(
        from entries: [(stylesheet: TCSSStylesheet, source: TCSSStylesheetSource?, sourceIndex: Int)]
    ) -> TCSSStyleModel {
        var diagnostics = entries.flatMap(\.stylesheet.diagnostics)
        let rules = entries.flatMap { entry in
            entry.stylesheet.rules.map { rule in
                TCSSStyleRule(
                    selectors: rule.selectors,
                    style: buildStyle(from: rule.declarations, diagnostics: &diagnostics),
                    line: rule.line,
                    sourceName: entry.source?.name,
                    sourceIndex: entry.sourceIndex
                )
            }
        }
        return TCSSStyleModel(rules: rules, diagnostics: diagnostics)
    }

    private func buildStyle(from declarations: [TCSSDeclaration], diagnostics: inout [TCSSDiagnostic]) -> TCSSStyle {
        var style = TCSSStyle()

        for declaration in declarations {
            let property = valueParser.canonicalPropertyName(declaration.property)
            switch property {
            case "color", "foreground":
                assignColor(declaration, to: \.terminalStyle.foreground, in: &style, diagnostics: &diagnostics)
            case "background", "background-color":
                assignColor(declaration, to: \.terminalStyle.background, in: &style, diagnostics: &diagnostics)
            case "text-style":
                assignTextStyle(declaration, to: &style, diagnostics: &diagnostics)
            case "bold":
                assignBool(declaration, to: \.terminalStyle.bold, in: &style, diagnostics: &diagnostics)
            case "dim":
                assignBool(declaration, to: \.terminalStyle.dim, in: &style, diagnostics: &diagnostics)
            case "italic":
                assignBool(declaration, to: \.terminalStyle.italic, in: &style, diagnostics: &diagnostics)
            case "underline":
                assignBool(declaration, to: \.terminalStyle.underline, in: &style, diagnostics: &diagnostics)
            case "strike", "strikethrough":
                assignBool(declaration, to: \.terminalStyle.strikethrough, in: &style, diagnostics: &diagnostics)
            case "inverse":
                assignBool(declaration, to: \.terminalStyle.inverse, in: &style, diagnostics: &diagnostics)
            case "blink":
                assignBool(declaration, to: \.terminalStyle.blink, in: &style, diagnostics: &diagnostics)
            case "width":
                assignLayoutLength(declaration, dimension: .width, in: &style, diagnostics: &diagnostics)
            case "height":
                assignLayoutLength(declaration, dimension: .height, in: &style, diagnostics: &diagnostics)
            case "min-width":
                assignLayoutConstraint(declaration, constraint: \.minWidth, in: &style, diagnostics: &diagnostics)
            case "min-height":
                assignLayoutConstraint(declaration, constraint: \.minHeight, in: &style, diagnostics: &diagnostics)
            case "max-width":
                assignLayoutConstraint(declaration, constraint: \.maxWidth, in: &style, diagnostics: &diagnostics)
            case "max-height":
                assignLayoutConstraint(declaration, constraint: \.maxHeight, in: &style, diagnostics: &diagnostics)
            case "padding":
                assignBoxEdges(declaration, to: \.layout.padding, in: &style, diagnostics: &diagnostics)
            case "margin":
                assignBoxEdges(declaration, to: \.layout.margin, in: &style, diagnostics: &diagnostics)
            case "text-align":
                assignTextAlign(declaration, to: &style, diagnostics: &diagnostics)
            case "overflow":
                assignOverflow(declaration, to: &style, diagnostics: &diagnostics)
            case "overflow-x":
                assignOverflowAxis(declaration, axis: .width, to: &style, diagnostics: &diagnostics)
            case "overflow-y":
                assignOverflowAxis(declaration, axis: .height, to: &style, diagnostics: &diagnostics)
            case "border":
                assignBorder(declaration, to: &style, diagnostics: &diagnostics)
            case "position":
                assignPosition(declaration, to: &style, diagnostics: &diagnostics)
            case "offset":
                assignOffset(declaration, to: &style, diagnostics: &diagnostics)
            case "offset-x":
                assignOffsetAxis(declaration, axis: .width, to: &style, diagnostics: &diagnostics)
            case "offset-y":
                assignOffsetAxis(declaration, axis: .height, to: &style, diagnostics: &diagnostics)
            case "divider-width":
                assignInt(declaration, to: \.layout.dividerWidth, in: &style, diagnostics: &diagnostics)
            case "divider-height":
                assignInt(declaration, to: \.layout.dividerHeight, in: &style, diagnostics: &diagnostics)
            case "divider-size":
                assignDividerSize(declaration, to: &style, diagnostics: &diagnostics)
            case "spacing", "gap":
                assignInt(declaration, to: \.layout.spacing, in: &style, diagnostics: &diagnostics)
            default:
                diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Unsupported TCSS property '\(declaration.property)'."))
            }
        }

        return style
    }

    private func assignColor(
        _ declaration: TCSSDeclaration,
        to keyPath: WritableKeyPath<TCSSStyle, TerminalColor?>,
        in style: inout TCSSStyle,
        diagnostics: inout [TCSSDiagnostic]
    ) {
        guard let color = valueParser.parseColor(declaration.value) else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Unsupported color value '\(declaration.value)' for '\(declaration.property)'."))
            return
        }
        style[keyPath: keyPath] = color
    }

    private func assignBool(
        _ declaration: TCSSDeclaration,
        to keyPath: WritableKeyPath<TCSSStyle, Bool?>,
        in style: inout TCSSStyle,
        diagnostics: inout [TCSSDiagnostic]
    ) {
        guard let value = valueParser.parseBool(declaration.value) else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Expected boolean value for '\(declaration.property)', got '\(declaration.value)'."))
            return
        }
        style[keyPath: keyPath] = value
    }

    private func assignInt(
        _ declaration: TCSSDeclaration,
        to keyPath: WritableKeyPath<TCSSStyle, Int?>,
        in style: inout TCSSStyle,
        diagnostics: inout [TCSSDiagnostic]
    ) {
        guard let value = valueParser.parseNonNegativeInt(declaration.value) else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Expected non-negative integer value for '\(declaration.property)', got '\(declaration.value)'."))
            return
        }
        style[keyPath: keyPath] = value
    }

    private func assignLayoutLength(
        _ declaration: TCSSDeclaration,
        dimension: FlowDimension,
        in style: inout TCSSStyle,
        diagnostics: inout [TCSSDiagnostic]
    ) {
        guard let length = valueParser.parseLayoutLength(declaration.value) else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Expected non-negative length value for '\(declaration.property)', got '\(declaration.value)'."))
            return
        }

        switch dimension {
        case .width:
            style.layout.widthLength = length
            if case .cells(let value) = length {
                style.layout.width = value
            } else {
                style.layout.width = nil
            }
        case .height:
            style.layout.heightLength = length
            if case .cells(let value) = length {
                style.layout.height = value
            } else {
                style.layout.height = nil
            }
        }
    }

    private func assignLayoutConstraint(
        _ declaration: TCSSDeclaration,
        constraint keyPath: WritableKeyPath<TCSSLayoutStyle, LayoutLength?>,
        in style: inout TCSSStyle,
        diagnostics: inout [TCSSDiagnostic]
    ) {
        guard let length = valueParser.parseLayoutLength(declaration.value) else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Expected non-negative length value for '\(declaration.property)', got '\(declaration.value)'."))
            return
        }
        style.layout[keyPath: keyPath] = length
    }

    private func assignBoxEdges(
        _ declaration: TCSSDeclaration,
        to keyPath: WritableKeyPath<TCSSStyle, TCSSBoxEdges?>,
        in style: inout TCSSStyle,
        diagnostics: inout [TCSSDiagnostic]
    ) {
        guard let edges = valueParser.parseBoxEdges(declaration.value) else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Expected one to four non-negative integers for '\(declaration.property)', got '\(declaration.value)'."))
            return
        }
        style[keyPath: keyPath] = edges
    }

    private func assignTextAlign(_ declaration: TCSSDeclaration, to style: inout TCSSStyle, diagnostics: inout [TCSSDiagnostic]) {
        guard let textAlign = valueParser.parseTextAlign(declaration.value) else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Unsupported text-align value '\(declaration.value)'."))
            return
        }
        style.layout.textAlign = textAlign
    }

    private func assignOverflow(_ declaration: TCSSDeclaration, to style: inout TCSSStyle, diagnostics: inout [TCSSDiagnostic]) {
        guard let overflow = valueParser.parseOverflow(declaration.value) else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Unsupported overflow value '\(declaration.value)'."))
            return
        }
        style.layout.overflow = overflow
    }

    private func assignOverflowAxis(
        _ declaration: TCSSDeclaration,
        axis: FlowDimension,
        to style: inout TCSSStyle,
        diagnostics: inout [TCSSDiagnostic]
    ) {
        guard let policy = valueParser.parseOverflowPolicy(declaration.value) else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Unsupported \(declaration.property) value '\(declaration.value)'."))
            return
        }
        var overflow = style.layout.overflow ?? .hidden
        switch axis {
        case .width:
            overflow.x = policy
        case .height:
            overflow.y = policy
        }
        style.layout.overflow = overflow
    }

    private func assignBorder(_ declaration: TCSSDeclaration, to style: inout TCSSStyle, diagnostics: inout [TCSSDiagnostic]) {
        guard let border = valueParser.parseBorderKind(declaration.value) else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Unsupported border value '\(declaration.value)'."))
            return
        }
        style.layout.border = border
    }

    private func assignPosition(_ declaration: TCSSDeclaration, to style: inout TCSSStyle, diagnostics: inout [TCSSDiagnostic]) {
        guard let position = valueParser.parsePosition(declaration.value) else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Unsupported position value '\(declaration.value)'."))
            return
        }
        style.layout.position = position
    }

    private func assignOffset(_ declaration: TCSSDeclaration, to style: inout TCSSStyle, diagnostics: inout [TCSSDiagnostic]) {
        guard let offset = valueParser.parseOffset(declaration.value) else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Expected two cell offsets for '\(declaration.property)', got '\(declaration.value)'."))
            return
        }
        style.layout.offset = offset
    }

    private func assignOffsetAxis(
        _ declaration: TCSSDeclaration,
        axis: FlowDimension,
        to style: inout TCSSStyle,
        diagnostics: inout [TCSSDiagnostic]
    ) {
        guard let value = valueParser.parseCellOffset(declaration.value) else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Expected cell offset for '\(declaration.property)', got '\(declaration.value)'."))
            return
        }
        var offset = style.layout.offset ?? Point(x: 0, y: 0)
        switch axis {
        case .width:
            offset.x = value
        case .height:
            offset.y = value
        }
        style.layout.offset = offset
    }

    private func assignTextStyle(_ declaration: TCSSDeclaration, to style: inout TCSSStyle, diagnostics: inout [TCSSDiagnostic]) {
        guard !declaration.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Declaration 'text-style' is missing a value."))
            return
        }
        guard let patch = valueParser.parseTextStylePatch(declaration.value) else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Unsupported text-style value '\(declaration.value)'."))
            return
        }
        style.terminalStyle.bold = patch.bold ?? style.terminalStyle.bold
        style.terminalStyle.dim = patch.dim ?? style.terminalStyle.dim
        style.terminalStyle.italic = patch.italic ?? style.terminalStyle.italic
        style.terminalStyle.underline = patch.underline ?? style.terminalStyle.underline
        style.terminalStyle.strikethrough = patch.strikethrough ?? style.terminalStyle.strikethrough
        style.terminalStyle.inverse = patch.inverse ?? style.terminalStyle.inverse
        style.terminalStyle.blink = patch.blink ?? style.terminalStyle.blink
    }

    private func assignDividerSize(_ declaration: TCSSDeclaration, to style: inout TCSSStyle, diagnostics: inout [TCSSDiagnostic]) {
        guard let value = valueParser.parseNonNegativeInt(declaration.value) else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Expected non-negative integer value for '\(declaration.property)', got '\(declaration.value)'."))
            return
        }
        style.layout.dividerWidth = value
        style.layout.dividerHeight = value
    }
}
