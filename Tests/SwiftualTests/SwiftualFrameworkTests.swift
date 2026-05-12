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
}
