import XCTest
@testable import Swiftual

final class TCSSValueParserTests: XCTestCase {
    private let parser = TCSSValueParser()

    func testParsesColorFamilies() {
        XCTAssertEqual(parser.parseColor("bright-white"), .brightWhite)
        XCTAssertEqual(parser.parseColor("bright_red"), .brightRed)
        XCTAssertEqual(parser.parseColor("bright-green"), .brightGreen)
        XCTAssertEqual(parser.parseColor("bright-yellow"), .brightYellow)
        XCTAssertEqual(parser.parseColor("bright-blue"), .brightBlue)
        XCTAssertEqual(parser.parseColor("bright-magenta"), .brightMagenta)
        XCTAssertEqual(parser.parseColor("bright-cyan"), .brightCyan)
        XCTAssertEqual(parser.parseColor("ansi(202)"), .ansi(202))
        XCTAssertEqual(parser.parseColor("rgb(255, 112, 67)"), .rgb(255, 112, 67))
        XCTAssertEqual(parser.parseColor("rgb(255 112 67)"), .rgb(255, 112, 67))
        XCTAssertEqual(parser.parseColor("rgb(255 112 67 / 50%)"), .rgb(255, 112, 67))
        XCTAssertEqual(parser.parseColor("rgb(100%, 0%, 50%)"), .rgb(255, 0, 128))
        XCTAssertEqual(parser.parseColor("rgba(255, 112, 67, 0.5)"), .rgb(255, 112, 67))
        XCTAssertEqual(parser.parseColor("rgba(100%, 0%, 50%, 25%)"), .rgb(255, 0, 128))
        XCTAssertEqual(parser.parseColor("hsl(0, 100%, 50%)"), .rgb(255, 0, 0))
        XCTAssertEqual(parser.parseColor("hsl(120 100% 25%)"), .rgb(0, 128, 0))
        XCTAssertEqual(parser.parseColor("hsl(120 100% 25% / 25%)"), .rgb(0, 128, 0))
        XCTAssertEqual(parser.parseColor("hsl(240deg 100% 50%)"), .rgb(0, 0, 255))
        XCTAssertEqual(parser.parseColor("hsla(240, 100%, 50%, 0.5)"), .rgb(0, 0, 255))
        XCTAssertEqual(parser.parseColor("hsl(480 100% 25%)"), .rgb(0, 128, 0))
        XCTAssertEqual(parser.parseColor("#0af"), .rgb(0x00, 0xaa, 0xff))
        XCTAssertEqual(parser.parseColor("#00aaff"), .rgb(0x00, 0xaa, 0xff))
        XCTAssertNil(parser.parseColor("rgb(300, 1, 1)"))
        XCTAssertNil(parser.parseColor("rgb(101%, 0%, 0%)"))
        XCTAssertNil(parser.parseColor("rgb(255 0 0 / 101%)"))
        XCTAssertNil(parser.parseColor("rgba(255, 0, 0, 2)"))
        XCTAssertNil(parser.parseColor("hsl(0, 101%, 50%)"))
        XCTAssertNil(parser.parseColor("hsl(0, 100, 50%)"))
        XCTAssertNil(parser.parseColor("hsla(0, 100%, 50%, 120%)"))
    }

    func testStyleModelParsesVariablesBeforeTypedValues() {
        let model = TCSSStyleModelBuilder().parse("""
        $accent: rgb(12, 34, 56);
        $wide: 18;
        Button {
            background: $accent;
            width: $wide;
        }
        """)

        let style = model.rules[0].style

        XCTAssertTrue(model.diagnostics.isEmpty)
        XCTAssertEqual(style.terminalStyle.background, .rgb(12, 34, 56))
        XCTAssertEqual(style.layout.width, 18)
    }

    func testParsesBooleansAndCellIntegers() {
        XCTAssertEqual(parser.parseBool("on"), true)
        XCTAssertEqual(parser.parseBool("false"), false)
        XCTAssertEqual(parser.parseNonNegativeInt("3.8cells"), 3)
        XCTAssertEqual(parser.parseNonNegativeInt("4ch"), 4)
        XCTAssertNil(parser.parseNonNegativeInt("-1"))
    }

    func testParsesOpacityValues() {
        XCTAssertEqual(parser.parseNumber("-12.5"), -12.5)
        XCTAssertEqual(parser.parsePercentage("-12.5%"), -0.125)
        XCTAssertEqual(parser.parsePercentage("125%"), 1.25)
        XCTAssertNil(parser.parseNumber("nan"))
        XCTAssertNil(parser.parseNumber("infinity"))
        XCTAssertNil(parser.parsePercentage("12.5"))

        XCTAssertEqual(parser.parseOpacity("0"), 0)
        XCTAssertEqual(parser.parseOpacity("1"), 1)
        XCTAssertEqual(parser.parseOpacity("0.42"), 0.42)
        XCTAssertEqual(parser.parseOpacity("75%"), 0.75)
        XCTAssertNil(parser.parseOpacity("-0.1"))
        XCTAssertNil(parser.parseOpacity("1.1"))
        XCTAssertNil(parser.parseOpacity("120%"))
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
        XCTAssertEqual(parser.parseGridSize("3"), TCSSGridSize(columns: 3))
        XCTAssertEqual(parser.parseGridSize("3 2"), TCSSGridSize(columns: 3, rows: 2))
        XCTAssertNil(parser.parseGridSize("0 2"))
        XCTAssertNil(parser.parseGridSize("3 2 1"))
        XCTAssertEqual(parser.parseGridGutter("2"), TCSSGridGutter(vertical: 2, horizontal: 2))
        XCTAssertEqual(parser.parseGridGutter("1 3"), TCSSGridGutter(vertical: 1, horizontal: 3))
        XCTAssertNil(parser.parseGridGutter("1 2 3"))

        XCTAssertEqual(parser.parseTextAlign("CENTER"), .center)
        XCTAssertEqual(parser.parseTextAlign("centre"), .center)
        XCTAssertEqual(parser.parseTextAlign("start"), .left)
        XCTAssertEqual(parser.parseTextAlign("end"), .right)
        XCTAssertEqual(parser.parseTextAlign("justify"), .justify)
        XCTAssertEqual(parser.parsePosition("absolute"), .absolute)
        XCTAssertEqual(parser.parsePosition("relative"), .relative)
        XCTAssertNil(parser.parsePosition("fixed"))
        XCTAssertEqual(parser.parseDisplay("none"), TCSSDisplay.none)
        XCTAssertEqual(parser.parseDisplay("block"), .block)
        XCTAssertNil(parser.parseDisplay("inline"))
        XCTAssertEqual(parser.parseVisibility("hidden"), .hidden)
        XCTAssertEqual(parser.parseVisibility("visible"), .visible)
        XCTAssertNil(parser.parseVisibility("collapse"))
        XCTAssertEqual(parser.parseLayoutKind("horizontal"), .horizontal)
        XCTAssertEqual(parser.parseLayoutKind("vertical"), .vertical)
        XCTAssertEqual(parser.parseLayoutKind("grid"), .grid)
        XCTAssertNil(parser.parseLayoutKind("inline"))
        XCTAssertEqual(parser.parseDock("bottom"), .bottom)
        XCTAssertNil(parser.parseDock("center"))
        XCTAssertEqual(
            parser.parseAlignment("center middle"),
            TCSSAlignment(horizontal: .center, vertical: .middle)
        )
        XCTAssertNil(parser.parseAlignment("center"))
        XCTAssertEqual(parser.parseName("overlay_modal"), "overlay-modal")
        XCTAssertNil(parser.parseName("base overlay"))
        XCTAssertNil(parser.parseName("1bad"))
        XCTAssertEqual(parser.parseNames("base overlay-modal"), ["base", "overlay-modal"])
        XCTAssertEqual(parser.parseNames("base, overlay_modal"), ["base", "overlay-modal"])
        XCTAssertNil(parser.parseNames("1bad"))
        XCTAssertEqual(parser.parseInteger("-2"), -2)
        XCTAssertEqual(parser.parseInteger("3.8cells"), 3)
        XCTAssertEqual(parser.parseInteger("-3.8ch"), -3)
        XCTAssertNil(parser.parseInteger("nan"))
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
        XCTAssertEqual(parser.parseBorderKind("outer"), .single)
        XCTAssertEqual(parser.parseBorderKind("panel"), .single)
        XCTAssertEqual(parser.parseBorderKind("wide"), .single)
        XCTAssertEqual(parser.parseBorderKind("tall"), .single)
        XCTAssertEqual(parser.parseBorderKind("hkey"), .single)
        XCTAssertEqual(parser.parseBorderKind("vkey"), .single)
        XCTAssertEqual(parser.parseBorderKind("double"), .double)
        XCTAssertEqual(parser.parseBorderKind("inner"), .double)
        XCTAssertEqual(parser.parseBorderKind("thick"), .double)
        XCTAssertEqual(parser.parseBorderKind("heavy"), .heavy)
        XCTAssertEqual(parser.parseBorderKind("blank"), .blank)
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

    func testStyleModelParsesTextAlignAliases() {
        let model = TCSSStyleModelBuilder().parse("""
        Label.left { text-align: start; }
        Label.centered { text-align: centre; }
        Label.right { text-align: end; }
        Label.copy { text-align: justify; }
        """)

        XCTAssertTrue(model.diagnostics.isEmpty)
        XCTAssertEqual(model.rules[0].style.layout.textAlign, .left)
        XCTAssertEqual(model.rules[1].style.layout.textAlign, .center)
        XCTAssertEqual(model.rules[2].style.layout.textAlign, .right)
        XCTAssertEqual(model.rules[3].style.layout.textAlign, .justify)
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
        Vertical { border: heavy; }
        Horizontal { border: blank; }
        Panel { border: vector; }
        """)

        XCTAssertEqual(model.rules[0].style.layout.border, .double)
        XCTAssertEqual(model.rules[1].style.layout.border, .heavy)
        XCTAssertEqual(model.rules[2].style.layout.border, .blank)
        XCTAssertEqual(model.rules[3].style.layout.border, .vector)
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

    func testStyleModelParsesOpacityProperties() {
        let model = TCSSStyleModelBuilder().parse("""
        Panel { opacity: 75%; text-opacity: 0.5; }
        Label { opacity: 1.2; }
        """)

        XCTAssertEqual(model.rules[0].style.visual.opacity, 0.75)
        XCTAssertEqual(model.rules[0].style.visual.textOpacity, 0.5)
        XCTAssertEqual(model.diagnostics.map(\.message), ["Expected opacity from 0 to 1 or 0% to 100% for 'opacity', got '1.2'."])
    }

    func testStyleModelParsesDisplayAndVisibilityProperties() {
        let model = TCSSStyleModelBuilder().parse("""
        Panel { display: none; visibility: hidden; }
        Label { display: inline; visibility: collapse; }
        """)

        XCTAssertEqual(model.rules[0].style.visual.display, TCSSDisplay.none)
        XCTAssertEqual(model.rules[0].style.visual.visibility, .hidden)
        XCTAssertEqual(model.diagnostics.map(\.message), [
            "Unsupported display value 'inline'.",
            "Unsupported visibility value 'collapse'."
        ])
    }

    func testStyleModelParsesLayoutPlacementProperties() {
        let model = TCSSStyleModelBuilder().parse("""
        Panel {
            layout: grid;
            grid-size: 4 3;
            grid-gutter: 1 2;
            dock: bottom;
            align: center middle;
            content-align: right bottom;
            layer: overlay;
            layers: base overlay modal;
        }
        Broken {
            layout: inline;
            dock: center;
            align: middle;
            align-horizontal: nowhere;
            content-align-vertical: sideways;
            layer: base overlay;
            layers: 123;
        }
        SplitAlignment {
            align-horizontal: right;
            align-vertical: bottom;
            content-align-horizontal: center;
            content-align-vertical: middle;
        }
        BadGrid {
            grid-size: 0 2;
            grid-gutter: 1 2 3;
        }
        """)

        let style = model.rules[0].style.layout
        let split = model.rules[2].style.layout
        XCTAssertEqual(style.layoutKind, .grid)
        XCTAssertEqual(style.gridSize, TCSSGridSize(columns: 4, rows: 3))
        XCTAssertEqual(style.gridGutter, TCSSGridGutter(vertical: 1, horizontal: 2))
        XCTAssertEqual(style.dock, .bottom)
        XCTAssertEqual(style.align, TCSSAlignment(horizontal: .center, vertical: .middle))
        XCTAssertEqual(style.contentAlign, TCSSAlignment(horizontal: .right, vertical: .bottom))
        XCTAssertEqual(style.layer, "overlay")
        XCTAssertEqual(style.layers, ["base", "overlay", "modal"])
        XCTAssertEqual(split.align, TCSSAlignment(horizontal: .right, vertical: .bottom))
        XCTAssertEqual(split.contentAlign, TCSSAlignment(horizontal: .center, vertical: .middle))
        XCTAssertEqual(model.diagnostics.map(\.message), [
            "Unsupported layout value 'inline'.",
            "Unsupported dock value 'center'.",
            "Expected horizontal and vertical alignment for 'align', got 'middle'.",
            "Expected horizontal alignment for 'align-horizontal', got 'nowhere'.",
            "Expected vertical alignment for 'content-align-vertical', got 'sideways'.",
            "Expected one layer name for 'layer', got 'base overlay'.",
            "Expected one or more layer names for 'layers', got '123'.",
            "Expected one or two positive integer values for 'grid-size', got '0 2'.",
            "Expected one or two non-negative integer values for 'grid-gutter', got '1 2 3'."
        ])
    }
}
