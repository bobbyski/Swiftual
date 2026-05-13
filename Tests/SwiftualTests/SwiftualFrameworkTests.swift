import XCTest
@testable import Swiftual

final class SwiftualFrameworkTests: XCTestCase {
    func testMenuBarCoreMovedWithoutDemoContainer() {
        var menuBar = MenuBar(menus: [
            Menu("File", items: [
                MenuItem("Quit") {}
            ])
        ])

        XCTAssertEqual(menuBar.handle(.key(.down)), .none)
        XCTAssertTrue(menuBar.isOpen)
        XCTAssertEqual(menuBar.handle(.key(.enter)), .quit)
    }

    func testCoreControlStillRenders() {
        var canvas = Canvas(size: TerminalSize(columns: 12, rows: 3))
        Button("Run", frame: Rect(x: 1, y: 1, width: 8, height: 1)).render(in: &canvas)

        XCTAssertEqual(canvas[3, 1].character, "R")
        XCTAssertEqual(canvas[1, 1].style.background, .brightWhite)
    }

    func testDataTableCompactPresentationRemainsDefault() {
        var canvas = Canvas(size: TerminalSize(columns: 18, rows: 5))
        DataTable(
            frame: Rect(x: 0, y: 0, width: 18, height: 4),
            columns: [
                DataTableColumn("A", width: 4),
                DataTableColumn("B", width: 4)
            ],
            rows: [["one", "two"]]
        ).render(in: &canvas)

        XCTAssertNotEqual(canvas[0, 0].character, "┌")
        XCTAssertEqual(canvas[4, 0].character, "|")
        XCTAssertEqual(canvas[0, 1].character, " ")
    }

    func testDataTableGridPresentationRendersDoubleBoxCharacters() {
        var canvas = Canvas(size: TerminalSize(columns: 18, rows: 6))
        DataTable(
            frame: Rect(x: 0, y: 0, width: 18, height: 5),
            columns: [
                DataTableColumn("A", width: 4),
                DataTableColumn("B", width: 4)
            ],
            rows: [["one", "two"]],
            presentation: .grid(.double)
        ).render(in: &canvas)

        XCTAssertEqual(canvas[0, 0].character, "╔")
        XCTAssertEqual(canvas[5, 0].character, "╦")
        XCTAssertEqual(canvas[10, 0].character, "╗")
        XCTAssertEqual(canvas[0, 2].character, "╠")
        XCTAssertEqual(canvas[5, 2].character, "╬")
        XCTAssertEqual(canvas[10, 4].character, "╝")
    }

    func testDataTableFramedPresentationRendersSolidBorderIntersections() {
        var canvas = Canvas(size: TerminalSize(columns: 18, rows: 6))
        DataTable(
            frame: Rect(x: 0, y: 0, width: 18, height: 5),
            columns: [
                DataTableColumn("A", width: 4),
                DataTableColumn("B", width: 4)
            ],
            rows: [["one", "two"]],
            presentation: .framed(.single)
        ).render(in: &canvas)

        XCTAssertEqual(canvas[0, 0].character, "┌")
        XCTAssertEqual(canvas[5, 0].character, "┬")
        XCTAssertEqual(canvas[10, 0].character, "┐")
        XCTAssertEqual(canvas[0, 2].character, "├")
        XCTAssertEqual(canvas[5, 2].character, "┼")
        XCTAssertEqual(canvas[0, 4].character, "└")
        XCTAssertEqual(canvas[5, 4].character, "┴")
        XCTAssertEqual(canvas[10, 4].character, "┘")
        XCTAssertEqual(canvas[5, 1].character, "│")
        XCTAssertEqual(canvas[5, 3].character, "│")
    }

    func testDataTableGridLinesUseTheRowStyleTheyBisect() {
        let selectedStyle = TerminalStyle(foreground: .brightWhite, background: .blue)
        var canvas = Canvas(size: TerminalSize(columns: 18, rows: 8))
        DataTable(
            frame: Rect(x: 0, y: 0, width: 18, height: 7),
            columns: [
                DataTableColumn("A", width: 4),
                DataTableColumn("B", width: 4)
            ],
            rows: [
                ["one", "two"],
                ["three", "four"]
            ],
            selectedRowIndex: 1,
            selectedRowStyle: selectedStyle,
            presentation: .grid(.single)
        ).render(in: &canvas)

        XCTAssertEqual(canvas[0, 5].character, "│")
        XCTAssertEqual(canvas[0, 5].style.background, selectedStyle.background)
        XCTAssertEqual(canvas[5, 5].style.background, selectedStyle.background)
    }

    func testFlowChildDisplayNoneDoesNotReserveLayout() {
        var canvas = Canvas(size: TerminalSize(columns: 12, rows: 3))
        let hidden = Label("Skip", frame: Rect(x: 0, y: 0, width: 4, height: 1))
        let shown = Label("Shown", frame: Rect(x: 0, y: 0, width: 5, height: 1))
        let flow = FlowContainer(frame: Rect(x: 0, y: 0, width: 12, height: 1), axis: .horizontal, spacing: FlowSpacing(main: 1), children: [
            FlowChild(hidden, reservesLayout: false, shouldRender: false),
            FlowChild(shown)
        ])

        let frames = flow.laidOutChildren()
        flow.render(in: &canvas)

        XCTAssertEqual(frames[0], Rect(x: 0, y: 0, width: 0, height: 0))
        XCTAssertEqual(frames[1], Rect(x: 0, y: 0, width: 5, height: 1))
        XCTAssertEqual(rowString(canvas, y: 0, width: 5), "Shown")
    }

    func testFlowChildVisibilityHiddenReservesLayoutWithoutRendering() {
        var canvas = Canvas(size: TerminalSize(columns: 12, rows: 3))
        let hidden = Label("Hide", frame: Rect(x: 0, y: 0, width: 4, height: 1))
        let shown = Label("Shown", frame: Rect(x: 0, y: 0, width: 5, height: 1))
        let flow = FlowContainer(frame: Rect(x: 0, y: 0, width: 12, height: 1), axis: .horizontal, spacing: FlowSpacing(main: 1), children: [
            FlowChild(hidden, reservesLayout: true, shouldRender: false),
            FlowChild(shown)
        ])

        let frames = flow.laidOutChildren()
        flow.render(in: &canvas)

        XCTAssertEqual(frames[0], Rect(x: 0, y: 0, width: 4, height: 1))
        XCTAssertEqual(frames[1], Rect(x: 5, y: 0, width: 5, height: 1))
        XCTAssertEqual(rowString(canvas, y: 0, width: 10), "     Shown")
    }

    func testFlowChildMarginConsumesMainAxisSpace() {
        let first = Label("One", frame: Rect(x: 0, y: 0, width: 3, height: 1))
        let second = Label("Two", frame: Rect(x: 0, y: 0, width: 3, height: 1))
        let flow = FlowContainer(frame: Rect(x: 0, y: 0, width: 12, height: 1), axis: .horizontal, children: [
            FlowChild(
                first,
                preferences: LayoutPreferences(margin: BoxEdges(top: 0, right: 2, bottom: 0, left: 1))
            ),
            FlowChild(second)
        ])

        let frames = flow.laidOutChildren()

        XCTAssertEqual(frames[0], Rect(x: 1, y: 0, width: 3, height: 1))
        XCTAssertEqual(frames[1], Rect(x: 6, y: 0, width: 3, height: 1))
    }

    func testFlowChildMarginReducesCrossAxisSpaceBeforeAlignment() {
        let child = Label("Wide", frame: Rect(x: 0, y: 0, width: 4, height: 1))
        let flow = FlowContainer(
            frame: Rect(x: 0, y: 0, width: 12, height: 3),
            axis: .vertical,
            alignment: FlowAlignment(horizontal: .right, vertical: .top),
            children: [
                FlowChild(
                    child,
                    preferences: LayoutPreferences(margin: BoxEdges(top: 1, right: 2, bottom: 0, left: 1))
                )
            ]
        )

        let frames = flow.laidOutChildren()

        XCTAssertEqual(frames[0], Rect(x: 6, y: 1, width: 4, height: 1))
    }

    func testFlowContainerHiddenOverflowClipsChildrenToContentFrame() {
        var canvas = Canvas(size: TerminalSize(columns: 8, rows: 1))
        let child = Label("Overflow", frame: Rect(x: 0, y: 0, width: 8, height: 1))
        let flow = FlowContainer(
            frame: Rect(x: 0, y: 0, width: 4, height: 1),
            axis: .horizontal,
            overflow: .hidden,
            children: [FlowChild(child)]
        )

        flow.render(in: &canvas)

        XCTAssertEqual(rowString(canvas, y: 0, width: 8), "Over    ")
    }

    func testFlowContainerVisibleOverflowRendersPastContentFrame() {
        var canvas = Canvas(size: TerminalSize(columns: 8, rows: 1))
        let child = Label("Overflow", frame: Rect(x: 0, y: 0, width: 8, height: 1))
        let flow = FlowContainer(
            frame: Rect(x: 0, y: 0, width: 4, height: 1),
            axis: .horizontal,
            overflow: .visible,
            children: [FlowChild(child)]
        )

        flow.render(in: &canvas)

        XCTAssertEqual(rowString(canvas, y: 0, width: 8), "Overflow")
    }

    func testFlowContainerScrollOverflowHonorsScrollOffset() {
        var canvas = Canvas(size: TerminalSize(columns: 8, rows: 1))
        let first = Label("One", frame: Rect(x: 0, y: 0, width: 3, height: 1))
        let second = Label("Two", frame: Rect(x: 0, y: 0, width: 3, height: 1))
        let flow = FlowContainer(
            frame: Rect(x: 0, y: 0, width: 4, height: 1),
            axis: .horizontal,
            spacing: FlowSpacing(main: 1),
            overflow: Overflow(x: .scroll, y: .hidden),
            scrollOffset: Point(x: 4, y: 0),
            children: [
                FlowChild(first),
                FlowChild(second)
            ]
        )

        flow.render(in: &canvas)

        XCTAssertEqual(rowString(canvas, y: 0, width: 8), "Two     ")
    }

    func testGridDisplayNoneDoesNotReserveCell() {
        var canvas = Canvas(size: TerminalSize(columns: 8, rows: 1))
        let hidden = Label("Hide", frame: Rect(x: 0, y: 0, width: 4, height: 1))
        let shown = Label("Show", frame: Rect(x: 0, y: 0, width: 4, height: 1))
        let grid = Grid(frame: Rect(x: 0, y: 0, width: 8, height: 1), columns: 2, children: [
            FlowChild(hidden, reservesLayout: false, shouldRender: false),
            FlowChild(shown)
        ])

        grid.render(in: &canvas)

        XCTAssertEqual(rowString(canvas, y: 0, width: 8), "Show    ")
    }

    func testGridVisibilityHiddenReservesCellWithoutRendering() {
        var canvas = Canvas(size: TerminalSize(columns: 8, rows: 1))
        let hidden = Label("Hide", frame: Rect(x: 0, y: 0, width: 4, height: 1))
        let shown = Label("Show", frame: Rect(x: 0, y: 0, width: 4, height: 1))
        let grid = Grid(frame: Rect(x: 0, y: 0, width: 8, height: 1), columns: 2, children: [
            FlowChild(hidden, reservesLayout: true, shouldRender: false),
            FlowChild(shown)
        ])

        grid.render(in: &canvas)

        XCTAssertEqual(rowString(canvas, y: 0, width: 8), "    Show")
    }

    func testTerminalStyleRendersExpandedAnsiStyleCodes() {
        let style = TerminalStyle(
            bold: true,
            dim: true,
            italic: true,
            underline: true,
            strikethrough: true,
            inverse: true,
            blink: true
        )

        XCTAssertEqual(style.ansiPrefix(), "\u{001B}[1;2;3;4;5;7;9m")
    }

    func testTextInputBlinkingCursorAlternatesHighlightWithoutTerminalBlink() {
        let input = TextInput(
            text: "Swift",
            frame: Rect(x: 0, y: 0, width: 8, height: 1),
            cursorIndex: 1,
            isFocused: true,
            focusedStyle: TerminalStyle(foreground: .brightWhite, background: .blue),
            cursorStyle: TerminalStyle(foreground: .black, background: .brightWhite, inverse: true, blink: true),
            cursorBlinkInterval: 0.5
        )
        var highlightedCanvas = Canvas(size: TerminalSize(columns: 8, rows: 1))
        var plainCanvas = Canvas(size: TerminalSize(columns: 8, rows: 1))

        input.render(in: &highlightedCanvas, now: Date(timeIntervalSinceReferenceDate: 0.1))
        input.render(in: &plainCanvas, now: Date(timeIntervalSinceReferenceDate: 0.6))

        XCTAssertEqual(highlightedCanvas[2, 0].character, "w")
        XCTAssertEqual(plainCanvas[2, 0].character, "w")
        XCTAssertEqual(highlightedCanvas[2, 0].style.background, .brightWhite)
        XCTAssertEqual(highlightedCanvas[2, 0].style.inverse, true)
        XCTAssertEqual(highlightedCanvas[2, 0].style.blink, false)
        XCTAssertEqual(plainCanvas[2, 0].style.background, .blue)
        XCTAssertEqual(plainCanvas[2, 0].style.inverse, false)
        XCTAssertEqual(plainCanvas[2, 0].style.blink, false)
    }

    private func rowString(_ canvas: Canvas, y: Int, width: Int) -> String {
        String((0..<width).map { canvas[$0, y].character })
    }
}
