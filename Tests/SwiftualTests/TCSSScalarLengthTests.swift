import XCTest
@testable import Swiftual

final class TCSSScalarLengthTests: XCTestCase {
    func testTCSSParsesTextualScalarSizingUnits() {
        let model = TCSSStyleModelBuilder().parse("""
        A { width: 1.9; height: 25%; }
        B { width: 2fr; height: auto; }
        C { width: 50w; height: 25h; }
        D { width: 80vw; height: 40vh; }
        E { width: fill; height: 3.8cells; }
        """)

        XCTAssertTrue(model.diagnostics.isEmpty)
        XCTAssertEqual(model.rules[0].style.layout.widthLength, .cells(1))
        XCTAssertEqual(model.rules[0].style.layout.heightLength, .percent(0.25))
        XCTAssertEqual(model.rules[1].style.layout.widthLength, .fraction(2))
        XCTAssertEqual(model.rules[1].style.layout.heightLength, .auto)
        XCTAssertEqual(model.rules[2].style.layout.widthLength, .containerWidth(0.5))
        XCTAssertEqual(model.rules[2].style.layout.heightLength, .containerHeight(0.25))
        XCTAssertEqual(model.rules[3].style.layout.widthLength, .viewportWidth(0.8))
        XCTAssertEqual(model.rules[3].style.layout.heightLength, .viewportHeight(0.4))
        XCTAssertEqual(model.rules[4].style.layout.widthLength, .fill)
        XCTAssertEqual(model.rules[4].style.layout.heightLength, .cells(3))
    }

    func testTCSSParsesTextualScalarMinAndMaxUnits() {
        let model = TCSSStyleModelBuilder().parse("""
        A {
            min-width: 25w;
            max-width: 50vw;
            min-height: 10h;
            max-height: 20vh;
        }
        """)

        XCTAssertTrue(model.diagnostics.isEmpty)
        XCTAssertEqual(model.rules[0].style.layout.minWidth, .containerWidth(0.25))
        XCTAssertEqual(model.rules[0].style.layout.maxWidth, .viewportWidth(0.5))
        XCTAssertEqual(model.rules[0].style.layout.minHeight, .containerHeight(0.1))
        XCTAssertEqual(model.rules[0].style.layout.maxHeight, .viewportHeight(0.2))
    }

    func testFlowContainerResolvesTextualScalarSizingUnits() {
        let child = Label("x", frame: Rect(x: 0, y: 0, width: 1, height: 1))
        let flow = FlowContainer(
            frame: Rect(x: 0, y: 0, width: 100, height: 40),
            axis: .vertical,
            viewportSize: TerminalSize(columns: 200, rows: 80),
            children: [
                FlowChild(child, preferences: LayoutPreferences(width: .containerWidth(0.5), height: .viewportHeight(0.25))),
                FlowChild(child, preferences: LayoutPreferences(width: .viewportWidth(0.25), height: .containerHeight(0.25)))
            ]
        )

        let frames = flow.laidOutChildren()

        XCTAssertEqual(frames[0].width, 50)
        XCTAssertEqual(frames[0].height, 20)
        XCTAssertEqual(frames[1].width, 50)
        XCTAssertEqual(frames[1].height, 10)
    }

    func testFlowContainerResolvesTextualScalarConstraints() {
        let child = Label("x", frame: Rect(x: 0, y: 0, width: 1, height: 1))
        let flow = FlowContainer(
            frame: Rect(x: 0, y: 0, width: 100, height: 40),
            axis: .vertical,
            viewportSize: TerminalSize(columns: 200, rows: 80),
            children: [
                FlowChild(child, preferences: LayoutPreferences(width: .fill, height: .cells(1), minHeight: .viewportHeight(0.25), maxWidth: .containerWidth(0.5))),
                FlowChild(child, preferences: LayoutPreferences(width: .cells(2), height: .cells(30), minWidth: .viewportWidth(0.1), maxHeight: .containerHeight(0.25)))
            ]
        )

        let frames = flow.laidOutChildren()

        XCTAssertEqual(frames[0].width, 50)
        XCTAssertEqual(frames[0].height, 20)
        XCTAssertEqual(frames[1].width, 20)
        XCTAssertEqual(frames[1].height, 10)
    }
}
