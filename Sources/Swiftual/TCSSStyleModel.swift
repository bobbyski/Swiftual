import Foundation

public struct TCSSStyleModel: Equatable, Sendable {
    public var rules: [TCSSStyleRule]
    public var diagnostics: [TCSSDiagnostic]

    public init(rules: [TCSSStyleRule] = [], diagnostics: [TCSSDiagnostic] = []) {
        self.rules = rules
        self.diagnostics = diagnostics
    }
}

public struct TCSSStyleRule: Equatable, Sendable {
    public var selectors: [TCSSSelector]
    public var style: TCSSStyle
    public var line: Int

    public init(selectors: [TCSSSelector], style: TCSSStyle, line: Int) {
        self.selectors = selectors
        self.style = style
        self.line = line
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
    public var minWidth: Int?
    public var minHeight: Int?
    public var maxWidth: Int?
    public var maxHeight: Int?
    public var padding: TCSSBoxEdges?
    public var margin: TCSSBoxEdges?
    public var textAlign: TCSSTextAlign?
    public var dividerWidth: Int?
    public var dividerHeight: Int?

    public init(
        width: Int? = nil,
        height: Int? = nil,
        minWidth: Int? = nil,
        minHeight: Int? = nil,
        maxWidth: Int? = nil,
        maxHeight: Int? = nil,
        padding: TCSSBoxEdges? = nil,
        margin: TCSSBoxEdges? = nil,
        textAlign: TCSSTextAlign? = nil,
        dividerWidth: Int? = nil,
        dividerHeight: Int? = nil
    ) {
        self.width = width
        self.height = height
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
        self.padding = padding
        self.margin = margin
        self.textAlign = textAlign
        self.dividerWidth = dividerWidth
        self.dividerHeight = dividerHeight
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
        var diagnostics = stylesheet.diagnostics
        let rules = stylesheet.rules.map { rule in
            TCSSStyleRule(
                selectors: rule.selectors,
                style: buildStyle(from: rule.declarations, diagnostics: &diagnostics),
                line: rule.line
            )
        }
        return TCSSStyleModel(rules: rules, diagnostics: diagnostics)
    }

    public func parse(_ source: String) -> TCSSStyleModel {
        build(from: TCSSParser().parse(source))
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
                assignInt(declaration, to: \.layout.width, in: &style, diagnostics: &diagnostics)
            case "height":
                assignInt(declaration, to: \.layout.height, in: &style, diagnostics: &diagnostics)
            case "min-width":
                assignInt(declaration, to: \.layout.minWidth, in: &style, diagnostics: &diagnostics)
            case "min-height":
                assignInt(declaration, to: \.layout.minHeight, in: &style, diagnostics: &diagnostics)
            case "max-width":
                assignInt(declaration, to: \.layout.maxWidth, in: &style, diagnostics: &diagnostics)
            case "max-height":
                assignInt(declaration, to: \.layout.maxHeight, in: &style, diagnostics: &diagnostics)
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
            return Int(value.dropLast(2))
        }
        if value.hasSuffix("cells") {
            return Int(value.dropLast(5))
        }
        if value.hasSuffix("cell") {
            return Int(value.dropLast(4))
        }
        return Int(value)
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
