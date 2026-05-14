import XCTest
@testable import Swiftual

final class TCSSParserTests: XCTestCase {
    func testParsesTopLevelVariablesInsideDeclarationValues() {
        let stylesheet = TCSSParser().parse("""
        $accent: bright-cyan;
        $panel: $accent;
        Button { color: $panel; }
        """)

        XCTAssertTrue(stylesheet.diagnostics.isEmpty)
        XCTAssertEqual(stylesheet.rules.count, 1)
        XCTAssertEqual(stylesheet.rules[0].selectors[0].raw, "Button")
        XCTAssertEqual(stylesheet.rules[0].declarations[0].property, "color")
        XCTAssertEqual(stylesheet.rules[0].declarations[0].value, "bright-cyan")
    }

    func testParsesDeclarationImportanceAfterVariables() {
        let stylesheet = TCSSParser().parse("""
        $accent: bright-cyan !important;
        Button {
            color: $accent;
            background: red;
        }
        """)

        XCTAssertTrue(stylesheet.diagnostics.isEmpty)
        XCTAssertEqual(stylesheet.rules[0].declarations[0].value, "bright-cyan")
        XCTAssertTrue(stylesheet.rules[0].declarations[0].isImportant)
        XCTAssertEqual(stylesheet.rules[0].declarations[1].value, "red")
        XCTAssertFalse(stylesheet.rules[0].declarations[1].isImportant)
    }

    func testImportantMarkerMustBeAtEndOfDeclarationValue() {
        let stylesheet = TCSSParser().parse("""
        Button { color: "!important but literal"; }
        """)

        XCTAssertEqual(stylesheet.rules[0].declarations[0].value, "\"!important but literal\"")
        XCTAssertFalse(stylesheet.rules[0].declarations[0].isImportant)
    }

    func testParsesUniversalSelectorAsExplicitWildcardSegment() {
        let stylesheet = TCSSParser().parse("""
        * { color: white; }
        Screen > *:focus { background: blue; }
        """)

        XCTAssertTrue(stylesheet.diagnostics.isEmpty)
        XCTAssertEqual(stylesheet.rules.count, 2)
        XCTAssertEqual(stylesheet.rules[0].selectors[0].segments[0].typeName, "*")
        XCTAssertEqual(stylesheet.rules[1].selectors[0].segments.map(\.typeName), ["Screen", "*"])
        XCTAssertEqual(stylesheet.rules[1].selectors[0].segments[1].pseudoStates, ["focus"])
    }

    func testReportsUnknownAndCyclicVariables() {
        let unknown = TCSSParser().parse("""
        Button { color: $missing; }
        """)
        let cyclic = TCSSParser().parse("""
        $a: $b;
        $b: $a;
        Button { color: $a; }
        """)

        XCTAssertEqual(unknown.rules[0].declarations[0].value, "$missing")
        XCTAssertTrue(unknown.diagnostics.contains { $0.message == "Unknown TCSS variable '$missing'." })
        XCTAssertTrue(cyclic.diagnostics.contains { $0.message == "Cyclic TCSS variable reference involving '$a'." })
    }
}
