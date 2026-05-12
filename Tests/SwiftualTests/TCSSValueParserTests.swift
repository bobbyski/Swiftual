import XCTest
@testable import Swiftual

final class TCSSValueParserTests: XCTestCase {
    private let parser = TCSSValueParser()

    func testParsesColorFamilies() {
        XCTAssertEqual(parser.parseColor("bright-white"), .brightWhite)
        XCTAssertEqual(parser.parseColor("ansi(202)"), .ansi(202))
        XCTAssertEqual(parser.parseColor("rgb(255, 112, 67)"), .rgb(255, 112, 67))
        XCTAssertEqual(parser.parseColor("#0af"), .rgb(0x00, 0xaa, 0xff))
        XCTAssertEqual(parser.parseColor("#00aaff"), .rgb(0x00, 0xaa, 0xff))
        XCTAssertNil(parser.parseColor("rgb(300, 1, 1)"))
    }

    func testParsesBooleansAndCellIntegers() {
        XCTAssertEqual(parser.parseBool("on"), true)
        XCTAssertEqual(parser.parseBool("false"), false)
        XCTAssertEqual(parser.parseNonNegativeInt("3.8cells"), 3)
        XCTAssertEqual(parser.parseNonNegativeInt("4ch"), 4)
        XCTAssertNil(parser.parseNonNegativeInt("-1"))
    }

    func testParsesLayoutLengthFamilies() {
        XCTAssertEqual(parser.parseLayoutLength("auto"), .auto)
        XCTAssertEqual(parser.parseLayoutLength("fill"), .fill)
        XCTAssertEqual(parser.parseLayoutLength("2fr"), .fraction(2))
        XCTAssertEqual(parser.parseLayoutLength("25%"), .percent(0.25))
        XCTAssertEqual(parser.parseLayoutLength("50w"), .containerWidth(0.5))
        XCTAssertEqual(parser.parseLayoutLength("10h"), .containerHeight(0.1))
        XCTAssertEqual(parser.parseLayoutLength("80vw"), .viewportWidth(0.8))
        XCTAssertEqual(parser.parseLayoutLength("40vh"), .viewportHeight(0.4))
        XCTAssertEqual(parser.parseLayoutLength("3.8cells"), .cells(3))
        XCTAssertNil(parser.parseLayoutLength("-2fr"))
    }

    func testParsesBoxEdgesAndTextStyles() {
        XCTAssertEqual(parser.parseBoxEdges("1"), TCSSBoxEdges(1))
        XCTAssertEqual(parser.parseBoxEdges("1 2"), TCSSBoxEdges(top: 1, right: 2, bottom: 1, left: 2))
        XCTAssertEqual(parser.parseBoxEdges("1 2 3"), TCSSBoxEdges(top: 1, right: 2, bottom: 3, left: 2))
        XCTAssertEqual(parser.parseBoxEdges("1 2 3 4"), TCSSBoxEdges(top: 1, right: 2, bottom: 3, left: 4))
        XCTAssertNil(parser.parseBoxEdges(""))

        XCTAssertEqual(parser.parseTextAlign("CENTER"), .center)
        XCTAssertEqual(parser.parsePosition("absolute"), .absolute)
        XCTAssertEqual(parser.parsePosition("relative"), .relative)
        XCTAssertNil(parser.parsePosition("fixed"))
        XCTAssertEqual(parser.parseCellOffset("-2"), -2)
        XCTAssertEqual(parser.parseCellOffset("3ch"), 3)
        XCTAssertEqual(parser.parseOffset("4 -2"), Point(x: 4, y: -2))
        XCTAssertNil(parser.parseOffset("4"))
        XCTAssertEqual(parser.parseOverflowPolicy("scroll"), .scroll)
        XCTAssertEqual(parser.parseOverflow("auto"), Overflow(x: .auto, y: .auto))
        XCTAssertEqual(parser.parseOverflow("hidden scroll"), Overflow(x: .hidden, y: .scroll))
        XCTAssertNil(parser.parseOverflow("hidden scroll visible"))
        XCTAssertNil(parser.parseOverflow("clip"))
        XCTAssertEqual(parser.parseBorderKind("solid"), .single)
        XCTAssertEqual(parser.parseBorderKind("double"), .double)
        XCTAssertEqual(parser.parseBorderKind("rounded"), .rounded)
        XCTAssertEqual(parser.parseBorderKind("none"), TCSSBorderKind.none)
        XCTAssertEqual(parser.parseBorderKind("vector"), .vector)
        XCTAssertNil(parser.parseBorderKind("sparkly"))
        XCTAssertEqual(
            parser.parseTextStylePatch("bold dim italic underline strikethrough inverse blink"),
            TCSSTerminalStylePatch(
                bold: true,
                dim: true,
                italic: true,
                underline: true,
                strikethrough: true,
                inverse: true,
                blink: true
            )
        )
        XCTAssertEqual(
            parser.parseTextStylePatch("plain"),
            TCSSTerminalStylePatch(
                bold: false,
                dim: false,
                italic: false,
                underline: false,
                strikethrough: false,
                inverse: false,
                blink: false
            )
        )
        XCTAssertNil(parser.parseTextStylePatch("sparkle"))
    }

    func testCanonicalizesPropertyAndValueNames() {
        XCTAssertEqual(parser.canonicalPropertyName(" background_color "), "background-color")
        XCTAssertEqual(parser.canonicalValue(" Bright_White "), "bright-white")
    }

    func testStyleModelParsesExpandedTerminalStyleProperties() {
        let model = TCSSStyleModelBuilder().parse("""
        Label { text-style: italic underline strikethrough dim blink inverse; }
        Button { bold: true; italic: true; underline: true; blink: false; }
        """)

        XCTAssertTrue(model.diagnostics.isEmpty)
        XCTAssertEqual(model.rules[0].style.terminalStyle.dim, true)
        XCTAssertEqual(model.rules[0].style.terminalStyle.italic, true)
        XCTAssertEqual(model.rules[0].style.terminalStyle.underline, true)
        XCTAssertEqual(model.rules[0].style.terminalStyle.strikethrough, true)
        XCTAssertEqual(model.rules[0].style.terminalStyle.inverse, true)
        XCTAssertEqual(model.rules[0].style.terminalStyle.blink, true)
        XCTAssertEqual(model.rules[1].style.terminalStyle.bold, true)
        XCTAssertEqual(model.rules[1].style.terminalStyle.italic, true)
        XCTAssertEqual(model.rules[1].style.terminalStyle.underline, true)
        XCTAssertEqual(model.rules[1].style.terminalStyle.blink, false)
    }

    func testStyleModelReportsUnsupportedTextStyleValues() {
        let model = TCSSStyleModelBuilder().parse("Button { text-style: sparkle; }")

        XCTAssertEqual(model.diagnostics.map(\.message), ["Unsupported text-style value 'sparkle'."])
    }

    func testStyleModelParsesOverflowProperties() {
        let model = TCSSStyleModelBuilder().parse("""
        FlowContainer { overflow: hidden scroll; }
        Vertical { overflow-x: visible; overflow-y: auto; }
        """)

        XCTAssertEqual(model.rules[0].style.layout.overflow, Overflow(x: .hidden, y: .scroll))
        XCTAssertEqual(model.rules[1].style.layout.overflow, Overflow(x: .visible, y: .auto))
    }

    func testStyleModelParsesBorderKinds() {
        let model = TCSSStyleModelBuilder().parse("""
        FlowContainer { border: double; }
        Vertical { border: none; }
        Horizontal { border: vector; }
        """)

        XCTAssertEqual(model.rules[0].style.layout.border, .double)
        XCTAssertEqual(model.rules[1].style.layout.border, TCSSBorderKind.none)
        XCTAssertEqual(model.rules[2].style.layout.border, .vector)
    }

    func testStyleModelParsesPositionAndOffsetProperties() {
        let model = TCSSStyleModelBuilder().parse("""
        Panel { position: absolute; offset: 4 -2; }
        Row { offset-x: -3; offset-y: 8ch; }
        """)

        XCTAssertEqual(model.rules[0].style.layout.position, .absolute)
        XCTAssertEqual(model.rules[0].style.layout.offset, Point(x: 4, y: -2))
        XCTAssertEqual(model.rules[1].style.layout.offset, Point(x: -3, y: 8))
    }
}
