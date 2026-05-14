import Foundation

public struct TCSSValueParser: Sendable {
    public init() {}

    public func parseColor(_ raw: String) -> TerminalColor? {
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
        case "bright-red", "brightred": return .brightRed
        case "bright-green", "brightgreen": return .brightGreen
        case "bright-yellow", "brightyellow": return .brightYellow
        case "bright-blue", "brightblue": return .brightBlue
        case "bright-magenta", "brightmagenta": return .brightMagenta
        case "bright-cyan", "brightcyan": return .brightCyan
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
            let inner = String(value.dropFirst(4).dropLast())
            guard let components = parseRGBComponents(inner) else {
                return nil
            }
            return .rgb(components.red, components.green, components.blue)
        }

        if value.hasPrefix("rgba("), value.hasSuffix(")") {
            let inner = String(value.dropFirst(5).dropLast())
            guard let components = parseRGBComponents(inner, allowsAlpha: true) else {
                return nil
            }
            return .rgb(components.red, components.green, components.blue)
        }

        if value.hasPrefix("hsl("), value.hasSuffix(")") {
            let inner = String(value.dropFirst(4).dropLast())
            guard let components = parseHSLComponents(inner) else {
                return nil
            }
            return hslToRGB(hue: components.hue, saturation: components.saturation, lightness: components.lightness)
        }

        if value.hasPrefix("hsla("), value.hasSuffix(")") {
            let inner = String(value.dropFirst(5).dropLast())
            guard let components = parseHSLComponents(inner, allowsAlpha: true) else {
                return nil
            }
            return hslToRGB(hue: components.hue, saturation: components.saturation, lightness: components.lightness)
        }

        if value.hasPrefix("#") {
            return parseHexColor(String(value.dropFirst()))
        }

        return nil
    }

    private func parseRGBComponents(_ raw: String, allowsAlpha: Bool = false) -> (red: UInt8, green: UInt8, blue: UInt8)? {
        let slashParts = raw.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
        let colorPart = slashParts.first.map(String.init) ?? raw
        if slashParts.count == 2,
           parseAlpha(String(slashParts[1])) == nil {
            return nil
        }

        let components: [String]
        if colorPart.contains(",") {
            components = colorPart.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else {
            components = colorPart.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        }

        let colorComponents: [String]
        if components.count == 4, allowsAlpha, slashParts.count == 1 {
            guard parseAlpha(components[3]) != nil else {
                return nil
            }
            colorComponents = Array(components.prefix(3))
        } else {
            colorComponents = components
        }

        guard colorComponents.count == 3,
              let red = parseRGBComponent(colorComponents[0]),
              let green = parseRGBComponent(colorComponents[1]),
              let blue = parseRGBComponent(colorComponents[2])
        else {
            return nil
        }
        return (red, green, blue)
    }

    private func parseRGBComponent(_ raw: String) -> UInt8? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasSuffix("%") {
            guard let percent = Double(value.dropLast()), percent >= 0, percent <= 100 else {
                return nil
            }
            return UInt8((percent * 255 / 100).rounded())
        }
        guard let intValue = Int(value), intValue >= 0, intValue <= 255 else {
            return nil
        }
        return UInt8(intValue)
    }

    private func parseHSLComponents(_ raw: String, allowsAlpha: Bool = false) -> (hue: Double, saturation: Double, lightness: Double)? {
        let slashParts = raw.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
        let colorPart = slashParts.first.map(String.init) ?? raw
        if slashParts.count == 2,
           parseAlpha(String(slashParts[1])) == nil {
            return nil
        }

        let components: [String]
        if colorPart.contains(",") {
            components = colorPart.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else {
            components = colorPart.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        }

        let colorComponents: [String]
        if components.count == 4, allowsAlpha, slashParts.count == 1 {
            guard parseAlpha(components[3]) != nil else {
                return nil
            }
            colorComponents = Array(components.prefix(3))
        } else {
            colorComponents = components
        }

        guard colorComponents.count == 3,
              let hue = parseHue(colorComponents[0]),
              let saturation = parseHSLPercentage(colorComponents[1]),
              let lightness = parseHSLPercentage(colorComponents[2])
        else {
            return nil
        }
        return (hue, saturation, lightness)
    }

    private func parseAlpha(_ raw: String) -> Double? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let alpha: Double?
        if value.hasSuffix("%") {
            alpha = parsePercentage(value)
        } else {
            alpha = parseNumber(value)
        }
        guard let alpha, alpha >= 0, alpha <= 1 else {
            return nil
        }
        return alpha
    }

    private func parseHue(_ raw: String) -> Double? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let numberText = value.hasSuffix("deg") ? String(value.dropLast(3)) : value
        guard let degrees = Double(numberText), degrees.isFinite else {
            return nil
        }
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        return normalized >= 0 ? normalized : normalized + 360
    }

    private func parseHSLPercentage(_ raw: String) -> Double? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.hasSuffix("%"),
              let percent = Double(value.dropLast()),
              percent >= 0,
              percent <= 100
        else {
            return nil
        }
        return percent / 100
    }

    private func hslToRGB(hue: Double, saturation: Double, lightness: Double) -> TerminalColor {
        let chroma = (1 - abs(2 * lightness - 1)) * saturation
        let huePrime = hue / 60
        let x = chroma * (1 - abs(huePrime.truncatingRemainder(dividingBy: 2) - 1))
        let (red1, green1, blue1): (Double, Double, Double)
        switch huePrime {
        case 0..<1:
            (red1, green1, blue1) = (chroma, x, 0)
        case 1..<2:
            (red1, green1, blue1) = (x, chroma, 0)
        case 2..<3:
            (red1, green1, blue1) = (0, chroma, x)
        case 3..<4:
            (red1, green1, blue1) = (0, x, chroma)
        case 4..<5:
            (red1, green1, blue1) = (x, 0, chroma)
        default:
            (red1, green1, blue1) = (chroma, 0, x)
        }
        let m = lightness - chroma / 2

        func byte(_ value: Double) -> UInt8 {
            UInt8(max(0, min(255, ((value + m) * 255).rounded())))
        }

        return .rgb(byte(red1), byte(green1), byte(blue1))
    }

    public func parseBool(_ raw: String) -> Bool? {
        switch canonicalValue(raw) {
        case "true", "yes", "on", "1": return true
        case "false", "no", "off", "0": return false
        default: return nil
        }
    }

    public func parseNumber(_ raw: String) -> Double? {
        let value = canonicalValue(raw)
        guard let number = Double(value), number.isFinite else {
            return nil
        }
        return number
    }

    public func parsePercentage(_ raw: String) -> Double? {
        let value = canonicalValue(raw)
        guard value.hasSuffix("%"),
              let number = parseNumber(String(value.dropLast()))
        else {
            return nil
        }
        return number / 100
    }

    public func parseOpacity(_ raw: String) -> Double? {
        let value = canonicalValue(raw)
        let opacity: Double?
        if value.hasSuffix("%") {
            opacity = parsePercentage(value)
        } else {
            opacity = parseNumber(value)
        }
        guard let opacity, opacity >= 0, opacity <= 1 else {
            return nil
        }
        return opacity
    }

    public func parseNonNegativeInt(_ raw: String) -> Int? {
        let value = canonicalValue(raw)
        if value.hasSuffix("ch") {
            return parseNonNegativeCellCount(String(value.dropLast(2)))
        }
        if value.hasSuffix("cells") {
            return parseNonNegativeCellCount(String(value.dropLast(5)))
        }
        if value.hasSuffix("cell") {
            return parseNonNegativeCellCount(String(value.dropLast(4)))
        }
        return parseNonNegativeCellCount(value)
    }

    public func parseInteger(_ raw: String) -> Int? {
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

    public func parseCellOffset(_ raw: String) -> Int? {
        parseInteger(raw)
    }

    public func parseOffset(_ raw: String) -> Point? {
        let tokens = raw
            .split(whereSeparator: { $0.isWhitespace })
            .map { String($0) }
        guard tokens.count == 2,
              let x = parseCellOffset(tokens[0]),
              let y = parseCellOffset(tokens[1])
        else {
            return nil
        }
        return Point(x: x, y: y)
    }

    public func parseLayoutLength(_ raw: String) -> LayoutLength? {
        let value = canonicalValue(raw)
        if value == "auto" {
            return .auto
        }
        if value == "fill" {
            return .fill
        }
        if value.hasSuffix("ch"), let cells = parseNonNegativeCellCount(String(value.dropLast(2))) {
            return .cells(cells)
        }
        if value.hasSuffix("cells"), let cells = parseNonNegativeCellCount(String(value.dropLast(5))) {
            return .cells(cells)
        }
        if value.hasSuffix("cell"), let cells = parseNonNegativeCellCount(String(value.dropLast(4))) {
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
        if value.hasSuffix("%"), let number = Double(value.dropLast()), number >= 0 {
            return .percent(number / 100)
        }
        if value.hasSuffix("fr"), let number = Double(value.dropLast(2)), number >= 0 {
            return .fraction(number)
        }
        guard let cells = parseNonNegativeInt(value) else {
            return nil
        }
        return .cells(cells)
    }

    public func parseBoxEdges(_ raw: String) -> TCSSBoxEdges? {
        let values = raw
            .split(whereSeparator: { $0.isWhitespace })
            .compactMap { parseNonNegativeInt(String($0)) }

        guard !values.isEmpty, values.count <= 4 else {
            return nil
        }

        switch values.count {
        case 1:
            return TCSSBoxEdges(values[0])
        case 2:
            return TCSSBoxEdges(top: values[0], right: values[1], bottom: values[0], left: values[1])
        case 3:
            return TCSSBoxEdges(top: values[0], right: values[1], bottom: values[2], left: values[1])
        default:
            return TCSSBoxEdges(top: values[0], right: values[1], bottom: values[2], left: values[3])
        }
    }

    public func parseGridSize(_ raw: String) -> TCSSGridSize? {
        let values = raw
            .split(whereSeparator: { $0.isWhitespace })
            .compactMap { parseNonNegativeInt(String($0)) }

        guard !values.isEmpty, values.count <= 2, values[0] > 0 else {
            return nil
        }
        if values.count == 2 {
            guard values[1] > 0 else { return nil }
            return TCSSGridSize(columns: values[0], rows: values[1])
        }
        return TCSSGridSize(columns: values[0])
    }

    public func parseGridGutter(_ raw: String) -> TCSSGridGutter? {
        let values = raw
            .split(whereSeparator: { $0.isWhitespace })
            .compactMap { parseNonNegativeInt(String($0)) }

        guard !values.isEmpty, values.count <= 2 else {
            return nil
        }
        let horizontal = values.count == 2 ? values[1] : values[0]
        return TCSSGridGutter(vertical: values[0], horizontal: horizontal)
    }

    public func parseTextAlign(_ raw: String) -> TCSSTextAlign? {
        switch canonicalValue(raw) {
        case "left", "start":
            .left
        case "center", "centre":
            .center
        case "right", "end":
            .right
        case "justify", "justified":
            .justify
        default:
            nil
        }
    }

    public func parsePosition(_ raw: String) -> TCSSPosition? {
        TCSSPosition(rawValue: canonicalValue(raw))
    }

    public func parseDisplay(_ raw: String) -> TCSSDisplay? {
        TCSSDisplay(rawValue: canonicalValue(raw))
    }

    public func parseVisibility(_ raw: String) -> TCSSVisibility? {
        TCSSVisibility(rawValue: canonicalValue(raw))
    }

    public func parseLayoutKind(_ raw: String) -> TCSSLayoutKind? {
        TCSSLayoutKind(rawValue: canonicalValue(raw))
    }

    public func parseDock(_ raw: String) -> TCSSDock? {
        TCSSDock(rawValue: canonicalValue(raw))
    }

    public func parseHorizontalAlignment(_ raw: String) -> TCSSHorizontalAlignment? {
        TCSSHorizontalAlignment(rawValue: canonicalValue(raw))
    }

    public func parseVerticalAlignment(_ raw: String) -> TCSSVerticalAlignment? {
        TCSSVerticalAlignment(rawValue: canonicalValue(raw))
    }

    public func parseAlignment(_ raw: String) -> TCSSAlignment? {
        let tokens = raw
            .split(whereSeparator: { $0.isWhitespace })
            .map { String($0) }
        guard tokens.count == 2,
              let horizontal = parseHorizontalAlignment(tokens[0]),
              let vertical = parseVerticalAlignment(tokens[1])
        else {
            return nil
        }
        return TCSSAlignment(horizontal: horizontal, vertical: vertical)
    }

    public func parseNames(_ raw: String) -> [String]? {
        let names = raw
            .split(whereSeparator: { $0.isWhitespace || $0 == "," })
            .map { canonicalValue(String($0)) }
        guard !names.isEmpty, names.allSatisfy(isValidName) else {
            return nil
        }
        return names
    }

    public func parseName(_ raw: String) -> String? {
        let value = canonicalValue(raw)
        guard isValidName(value) else {
            return nil
        }
        return value
    }

    public func parseOverflowPolicy(_ raw: String) -> OverflowPolicy? {
        switch canonicalValue(raw) {
        case "visible": return .visible
        case "hidden": return .hidden
        case "scroll": return .scroll
        case "auto": return .auto
        default: return nil
        }
    }

    public func parseOverflow(_ raw: String) -> Overflow? {
        let tokens = raw
            .split(whereSeparator: { $0.isWhitespace })
            .map { String($0) }

        guard !tokens.isEmpty, tokens.count <= 2 else {
            return nil
        }
        guard let first = parseOverflowPolicy(tokens[0]) else {
            return nil
        }
        let second = tokens.count == 2 ? parseOverflowPolicy(tokens[1]) : first
        guard let second else {
            return nil
        }
        return Overflow(x: first, y: second)
    }

    public func parseBorderKind(_ raw: String) -> TCSSBorderKind? {
        switch canonicalValue(raw) {
        case "none", "hidden": return TCSSBorderKind.none
        case "single", "solid", "outer", "panel", "wide", "tall", "hkey", "vkey": return .single
        case "double", "inner", "thick": return .double
        case "heavy": return .heavy
        case "dashed", "dash": return .dashed
        case "rounded", "round": return .rounded
        case "ascii": return .ascii
        case "blank": return .blank
        case "vector": return .vector
        default: return nil
        }
    }

    public func parseTextStylePatch(_ raw: String) -> TCSSTerminalStylePatch? {
        let tokens = raw
            .split(whereSeparator: { $0.isWhitespace || $0 == "," })
            .map { canonicalValue(String($0)) }

        guard !tokens.isEmpty else {
            return nil
        }

        var patch = TCSSTerminalStylePatch()
        for token in tokens {
            switch token {
            case "bold":
                patch.bold = true
            case "dim":
                patch.dim = true
            case "italic":
                patch.italic = true
            case "underline":
                patch.underline = true
            case "strike", "strikethrough":
                patch.strikethrough = true
            case "inverse", "reverse":
                patch.inverse = true
            case "blink":
                patch.blink = true
            case "none", "plain", "normal":
                patch.bold = false
                patch.dim = false
                patch.italic = false
                patch.underline = false
                patch.strikethrough = false
                patch.inverse = false
                patch.blink = false
            default:
                return nil
            }
        }
        return patch
    }

    public func canonicalPropertyName(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")
    }

    public func canonicalValue(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")
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

    private func parseNonNegativeCellCount(_ raw: String) -> Int? {
        guard let value = parseCellCount(raw), value >= 0 else { return nil }
        return value
    }

    private func parseCellCount(_ raw: String) -> Int? {
        guard let value = Double(raw), value.isFinite else { return nil }
        return Int(value.rounded(.towardZero))
    }

    private func isValidName(_ raw: String) -> Bool {
        guard let first = raw.first, first.isLetter || first == "_" else {
            return false
        }
        return raw.allSatisfy { character in
            character.isLetter || character.isNumber || character == "-" || character == "_"
        }
    }
}
