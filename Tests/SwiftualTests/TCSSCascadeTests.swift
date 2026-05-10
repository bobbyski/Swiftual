import XCTest
@testable import Swiftual

final class TCSSCascadeTests: XCTestCase {
    func testMultipleStylesheetSourcesUseDeterministicSourceOrder() {
        let model = TCSSStyleModelBuilder().parse([
            TCSSStylesheetSource(name: "base.tcss", source: """
            Button { background: blue; color: white; }
            """),
            TCSSStylesheetSource(name: "theme.tcss", source: """
            Button { background: green; }
            """),
            TCSSStylesheetSource(name: "target.tcss", source: """
            Button { color: yellow; }
            """)
        ])

        let style = TCSSCascade(model: model).style(for: TCSSStyleContext(typeName: "Button"))

        XCTAssertTrue(model.diagnostics.isEmpty)
        XCTAssertEqual(style.terminalStyle.background, .green)
        XCTAssertEqual(style.terminalStyle.foreground, .yellow)
    }

    func testHigherSpecificityStillWinsAcrossMultipleSources() {
        let model = TCSSStyleModelBuilder().parse([
            TCSSStylesheetSource(name: "base.tcss", source: """
            Button.primary { background: blue; }
            """),
            TCSSStylesheetSource(name: "theme.tcss", source: """
            Button { background: green; }
            """)
        ])

        let style = TCSSCascade(model: model).style(
            for: TCSSStyleContext(typeName: "Button", classNames: ["primary"])
        )

        XCTAssertTrue(model.diagnostics.isEmpty)
        XCTAssertEqual(style.terminalStyle.background, .blue)
    }

    func testMultiClassSelectorRequiresAllClasses() {
        let model = TCSSStyleModelBuilder().parse("""
        Button.primary.danger { background: red; color: bright-white; }
        Button.primary { background: blue; }
        """)
        let cascade = TCSSCascade(model: model)

        let primary = cascade.style(for: TCSSStyleContext(typeName: "Button", classNames: ["primary"]))
        let danger = cascade.style(for: TCSSStyleContext(typeName: "Button", classNames: ["primary", "danger"]))

        XCTAssertTrue(model.diagnostics.isEmpty)
        XCTAssertEqual(primary.terminalStyle.background, .blue)
        XCTAssertNil(primary.terminalStyle.foreground)
        XCTAssertEqual(danger.terminalStyle.background, .red)
        XCTAssertEqual(danger.terminalStyle.foreground, .brightWhite)
    }

    func testTypeClassAndPseudoSpecificityCombine() {
        let model = TCSSStyleModelBuilder().parse("""
        Button.primary { background: blue; }
        Button.primary:focus { background: green; text-style: bold; }
        Button:focus { background: yellow; }
        """)

        let style = TCSSCascade(model: model).style(
            for: TCSSStyleContext(typeName: "Button", classNames: ["primary"], pseudoStates: ["focus"])
        )

        XCTAssertTrue(model.diagnostics.isEmpty)
        XCTAssertEqual(style.terminalStyle.background, .green)
        XCTAssertEqual(style.terminalStyle.bold, true)
    }
}
