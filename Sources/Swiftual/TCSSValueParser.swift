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

    public func parseBool(_ raw: String) -> Bool? {
        switch canonicalValue(raw) {
        case "true", "yes", "on", "1": return true
        case "false", "no", "off", "0": return false
        default: return nil
        }
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

    public func parseCellOffset(_ raw: String) -> Int? {
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

    public func parseTextAlign(_ raw: String) -> TCSSTextAlign? {
        TCSSTextAlign(rawValue: canonicalValue(raw))
    }

    public func parsePosition(_ raw: String) -> TCSSPosition? {
        TCSSPosition(rawValue: canonicalValue(raw))
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
        case "single", "solid": return .single
        case "double", "heavy": return .double
        case "dashed", "dash": return .dashed
        case "rounded", "round": return .rounded
        case "ascii": return .ascii
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
        guard let value = Double(raw) else { return nil }
        return Int(value.rounded(.towardZero))
    }
}
