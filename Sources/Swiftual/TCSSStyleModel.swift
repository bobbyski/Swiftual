import Foundation

public struct TCSSStyleModel: Equatable, Sendable {
    public var rules: [TCSSStyleRule]
    public var diagnostics: [TCSSDiagnostic]

    public init(rules: [TCSSStyleRule] = [], diagnostics: [TCSSDiagnostic] = []) {
        self.rules = rules
        self.diagnostics = diagnostics
    }
}

public struct TCSSStylesheetSource: Equatable, Sendable {
    public var name: String
    public var source: String

    public init(name: String, source: String) {
        self.name = name
        self.source = source
    }
}

public protocol TCSSStylesheetProviding: Sendable {
    var tcssStylesheetSource: TCSSStylesheetSource { get }
}

extension TCSSStylesheetSource: TCSSStylesheetProviding {
    public var tcssStylesheetSource: TCSSStylesheetSource { self }
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
    public var inverse: Bool?

    public init(
        foreground: TerminalColor? = nil,
        background: TerminalColor? = nil,
        bold: Bool? = nil,
        inverse: Bool? = nil
    ) {
        self.foreground = foreground
        self.background = background
        self.bold = bold
        self.inverse = inverse
    }

    public func applied(to base: TerminalStyle) -> TerminalStyle {
        TerminalStyle(
            foreground: foreground ?? base.foreground,
            background: background ?? base.background,
            bold: bold ?? base.bold,
            inverse: inverse ?? base.inverse
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

public struct TCSSStyleModelBuilder: Sendable {
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
        let parser = TCSSParser()
        return build(
            from: sources.enumerated().map { index, source in
                (stylesheet: parser.parse(source.source), source: Optional(source), sourceIndex: index)
            }
        )
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
            let property = canonicalPropertyName(declaration.property)
            switch property {
            case "color", "foreground":
                assignColor(declaration, to: \.terminalStyle.foreground, in: &style, diagnostics: &diagnostics)
            case "background", "background-color":
                assignColor(declaration, to: \.terminalStyle.background, in: &style, diagnostics: &diagnostics)
            case "text-style":
                assignTextStyle(declaration, to: &style, diagnostics: &diagnostics)
            case "bold":
                assignBool(declaration, to: \.terminalStyle.bold, in: &style, diagnostics: &diagnostics)
            case "inverse":
                assignBool(declaration, to: \.terminalStyle.inverse, in: &style, diagnostics: &diagnostics)
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
        guard let color = parseColor(declaration.value) else {
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
        guard let value = parseBool(declaration.value) else {
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
        guard let value = parseInt(declaration.value), value >= 0 else {
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
        guard let length = parseLayoutLength(declaration.value) else {
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
        guard let length = parseLayoutLength(declaration.value) else {
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
        let values = declaration.value
            .split(whereSeparator: { $0.isWhitespace })
            .compactMap { parseInt(String($0)) }

        guard !values.isEmpty, values.count <= 4, values.allSatisfy({ $0 >= 0 }) else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Expected one to four non-negative integers for '\(declaration.property)', got '\(declaration.value)'."))
            return
        }

        let edges: TCSSBoxEdges
        switch values.count {
        case 1:
            edges = TCSSBoxEdges(values[0])
        case 2:
            edges = TCSSBoxEdges(top: values[0], right: values[1], bottom: values[0], left: values[1])
        case 3:
            edges = TCSSBoxEdges(top: values[0], right: values[1], bottom: values[2], left: values[1])
        default:
            edges = TCSSBoxEdges(top: values[0], right: values[1], bottom: values[2], left: values[3])
        }
        style[keyPath: keyPath] = edges
    }

    private func assignTextAlign(_ declaration: TCSSDeclaration, to style: inout TCSSStyle, diagnostics: inout [TCSSDiagnostic]) {
        let value = canonicalValue(declaration.value)
        guard let textAlign = TCSSTextAlign(rawValue: value) else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Unsupported text-align value '\(declaration.value)'."))
            return
        }
        style.layout.textAlign = textAlign
    }

    private func assignTextStyle(_ declaration: TCSSDeclaration, to style: inout TCSSStyle, diagnostics: inout [TCSSDiagnostic]) {
        let tokens = declaration.value
            .split(whereSeparator: { $0.isWhitespace || $0 == "," })
            .map { canonicalValue(String($0)) }

        guard !tokens.isEmpty else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Declaration 'text-style' is missing a value."))
            return
        }

        for token in tokens {
            switch token {
            case "bold":
                style.terminalStyle.bold = true
            case "inverse", "reverse":
                style.terminalStyle.inverse = true
            case "none", "plain", "normal":
                style.terminalStyle.bold = false
                style.terminalStyle.inverse = false
            default:
                diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Unsupported text-style value '\(token)'."))
            }
        }
    }

    private func assignDividerSize(_ declaration: TCSSDeclaration, to style: inout TCSSStyle, diagnostics: inout [TCSSDiagnostic]) {
        guard let value = parseInt(declaration.value), value >= 0 else {
            diagnostics.append(TCSSDiagnostic(line: declaration.line, message: "Expected non-negative integer value for '\(declaration.property)', got '\(declaration.value)'."))
            return
        }
        style.layout.dividerWidth = value
        style.layout.dividerHeight = value
    }

    private func parseColor(_ raw: String) -> TerminalColor? {
        let value = canonicalValue(raw)
        switch value {
        case "black": return .black
        case "red": return .red
        case "green": return .green
        case "yellow": return .yellow
        case "blue": return .blue
        case "magenta": return .magenta
        case "cyan": return .cyan
        case "white": return .white
        case "bright-black", "brightblack": return .brightBlack
        case "bright-white", "brightwhite": return .brightWhite
        default:
            break
        }

        if value.hasPrefix("ansi("), value.hasSuffix(")") {
            let inner = value.dropFirst(5).dropLast().trimmingCharacters(in: .whitespacesAndNewlines)
            if let index = Int(inner), index >= 0, index <= 255 {
                return .ansi(index)
            }
        }

        if value.hasPrefix("rgb("), value.hasSuffix(")") {
            let parts = value.dropFirst(4).dropLast().split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard parts.count == 3,
                  let red = UInt8(parts[0]),
                  let green = UInt8(parts[1]),
                  let blue = UInt8(parts[2])
            else {
                return nil
            }
            return .rgb(red, green, blue)
        }

        if value.hasPrefix("#") {
            return parseHexColor(String(value.dropFirst()))
        }

        return nil
    }

    private func parseHexColor(_ hex: String) -> TerminalColor? {
        let expanded: String
        if hex.count == 3 {
            expanded = hex.map { "\($0)\($0)" }.joined()
        } else {
            expanded = hex
        }

        guard expanded.count == 6, let value = Int(expanded, radix: 16) else {
            return nil
        }

        return .rgb(
            UInt8((value >> 16) & 0xff),
            UInt8((value >> 8) & 0xff),
            UInt8(value & 0xff)
        )
    }

    private func parseBool(_ raw: String) -> Bool? {
        switch canonicalValue(raw) {
        case "true", "yes", "on", "1": return true
        case "false", "no", "off", "0": return false
        default: return nil
        }
    }

    private func parseInt(_ raw: String) -> Int? {
        let value = canonicalValue(raw)
        if value.hasSuffix("ch") {
            return parseCellCount(String(value.dropLast(2)))
        }
        if value.hasSuffix("cells") {
            return parseCellCount(String(value.dropLast(5)))
        }
        if value.hasSuffix("cell") {
            return parseCellCount(String(value.dropLast(4)))
        }
        return parseCellCount(value)
    }

    private func parseLayoutLength(_ raw: String) -> LayoutLength? {
        let value = canonicalValue(raw)
        if value == "auto" {
            return .auto
        }
        if value == "fill" {
            return .fill
        }
        if value.hasSuffix("ch"), let cells = parseCellCount(String(value.dropLast(2))) {
            return .cells(cells)
        }
        if value.hasSuffix("cells"), let cells = parseCellCount(String(value.dropLast(5))) {
            return .cells(cells)
        }
        if value.hasSuffix("cell"), let cells = parseCellCount(String(value.dropLast(4))) {
            return .cells(cells)
        }
        if value.hasSuffix("vw"), let number = Double(value.dropLast(2)), number >= 0 {
            return .viewportWidth(number / 100)
        }
        if value.hasSuffix("vh"), let number = Double(value.dropLast(2)), number >= 0 {
            return .viewportHeight(number / 100)
        }
        if value.hasSuffix("w"), let number = Double(value.dropLast()), number >= 0 {
            return .containerWidth(number / 100)
        }
        if value.hasSuffix("h"), let number = Double(value.dropLast()), number >= 0 {
            return .containerHeight(number / 100)
        }
        if value.hasSuffix("%"), let number = Double(value.dropLast()) {
            return .percent(number / 100)
        }
        if value.hasSuffix("fr"), let number = Double(value.dropLast(2)) {
            return .fraction(number)
        }
        guard let cells = parseInt(value), cells >= 0 else {
            return nil
        }
        return .cells(cells)
    }

    private func parseCellCount(_ raw: String) -> Int? {
        guard let value = Double(raw), value >= 0 else { return nil }
        return Int(value.rounded(.towardZero))
    }

    private func canonicalPropertyName(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")
    }

    private func canonicalValue(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")
    }
}
