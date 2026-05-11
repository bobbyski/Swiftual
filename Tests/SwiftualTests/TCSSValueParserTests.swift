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
        XCTAssertEqual(parser.parseTextStylePatch("bold inverse"), TCSSTerminalStylePatch(bold: true, inverse: true))
        XCTAssertEqual(parser.parseTextStylePatch("plain"), TCSSTerminalStylePatch(bold: false, inverse: false))
        XCTAssertNil(parser.parseTextStylePatch("italic"))
    }

    func testCanonicalizesPropertyAndValueNames() {
        XCTAssertEqual(parser.canonicalPropertyName(" background_color "), "background-color")
        XCTAssertEqual(parser.canonicalValue(" Bright_White "), "bright-white")
    }

    func testStyleModelReportsUnsupportedTextStyleValues() {
        let model = TCSSStyleModelBuilder().parse("Button { text-style: italic; }")

        XCTAssertEqual(model.diagnostics.map(\.message), ["Unsupported text-style value 'italic'."])
    }
}
