import XCTest
@testable import Swiftual

final class SwiftualTests: XCTestCase {
    func testTerminalDetectorCanSelectANSIManually() {
        let backend = TerminalDetector.detect(selection: .manual(.ansi))
        XCTAssertEqual(backend.kind, .ansi)
    }

    func testTerminalDetectorCanSelectVT100Manually() {
        let backend = TerminalDetector.detect(selection: .manual(.vt100))
        XCTAssertEqual(backend.kind, .vt100)
    }

    func testMenuOpensAndQuitActivatesWithKeyboard() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertEqual(view.handle(.key(.down)), .none)
        XCTAssertEqual(view.handle(.key(.enter)), .quit)
    }

    func testMenuOpensAndQuitActivatesWithMouse() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 1, y: 0), pressed: true))), .none)
        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 1, y: 1), pressed: true))), .quit)
    }

    func testRenderContainsBlueMenuBarAndGreyBody() {
        let view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        let canvas = view.render(size: TerminalSize(columns: 20, rows: 6))
        XCTAssertEqual(canvas[0, 0].style.background, .blue)
        XCTAssertEqual(canvas[8, 0].style.background, .blue)
        XCTAssertEqual(canvas[0, 1].style.background, .brightBlack)
    }

    func testFocusedMenuMatchesMenuBarUntilOpened() {
        var menuBar = MenuBar(
            menus: [
                Menu("File", items: [
                    MenuItem("Quit") {}
                ])
            ]
        )
        var canvas = Canvas(size: TerminalSize(columns: 20, rows: 4))

        menuBar.render(in: &canvas)
        XCTAssertEqual(canvas[1, 0].style.foreground, .brightWhite)
        XCTAssertEqual(canvas[1, 0].style.background, .blue)

        _ = menuBar.handle(.key(.down))
        canvas = Canvas(size: TerminalSize(columns: 20, rows: 4))
        menuBar.render(in: &canvas)
        XCTAssertEqual(canvas[1, 0].style.foreground, .blue)
        XCTAssertEqual(canvas[1, 0].style.background, .brightWhite)
    }

    func testANSIBackendRendersThroughTerminalDeviceProtocol() throws {
        let device = VirtualTerminalDevice(size: TerminalSize(columns: 6, rows: 2))
        let backend = ANSITerminalBackend()
        var canvas = Canvas(size: device.size())
        canvas.drawText("Hi", at: Point(x: 0, y: 0), style: TerminalStyle(foreground: .white, background: .blue))

        try backend.render(canvas, device: device)

        XCTAssertTrue(device.output.contains("\u{001B}[?7l\u{001B}[H"))
        XCTAssertTrue(device.output.contains("\u{001B}[?7h"))
        XCTAssertTrue(device.output.contains("Hi"))
        XCTAssertTrue(device.output.contains("\u{001B}[37;44m"))
    }

    func testANSIBackendDoesNotScrollLastRenderedRow() throws {
        let device = VirtualTerminalDevice(size: TerminalSize(columns: 4, rows: 2))
        let backend = ANSITerminalBackend()
        var canvas = Canvas(size: device.size())
        canvas.drawText("Menu", at: Point(x: 0, y: 0), style: TerminalStyle(foreground: .white, background: .blue))
        canvas.drawText("Body", at: Point(x: 0, y: 1), style: TerminalStyle(foreground: .white, background: .brightBlack))

        try backend.render(canvas, device: device)

        XCTAssertFalse(device.output.hasSuffix("\r\n"))
    }

    func testButtonRendersFocusedState() {
        var button = Button("Run", frame: Rect(x: 2, y: 1, width: 8, height: 1))
        button.isFocused = true
        var canvas = Canvas(size: TerminalSize(columns: 16, rows: 4))

        button.render(in: &canvas)

        XCTAssertEqual(canvas[2, 1].style.background, .blue)
        XCTAssertEqual(canvas[4, 1].character, "R")
        XCTAssertEqual(canvas[4, 1].style.bold, true)
    }

    func testButtonActivatesWithKeyboardWhenFocused() {
        let recorder = ActionRecorder()
        var button = Button("Run", frame: Rect(x: 0, y: 0, width: 8, height: 1), isFocused: true) {
            recorder.activate()
        }

        let command = button.handle(.key(.enter))

        XCTAssertEqual(command, .activated("Run"))
        XCTAssertEqual(recorder.count, 1)
    }

    func testButtonIgnoresKeyboardWhenNotFocused() {
        let recorder = ActionRecorder()
        var button = Button("Run", frame: Rect(x: 0, y: 0, width: 8, height: 1), isFocused: false) {
            recorder.activate()
        }

        let command = button.handle(.key(.enter))

        XCTAssertEqual(command, .none)
        XCTAssertEqual(recorder.count, 0)
    }

    func testButtonActivatesWithMouseInsideFrame() {
        let recorder = ActionRecorder()
        var button = Button("Run", frame: Rect(x: 2, y: 1, width: 8, height: 1)) {
            recorder.activate()
        }

        let command = button.handle(.mouse(MouseEvent(button: .left, location: Point(x: 3, y: 1), pressed: true)))

        XCTAssertEqual(command, .activated("Run"))
        XCTAssertEqual(recorder.count, 1)
    }

    func testLabelRendersStyledText() {
        var canvas = Canvas(size: TerminalSize(columns: 12, rows: 3))
        let label = Label(
            "Hello",
            frame: Rect(x: 2, y: 1, width: 8, height: 1),
            style: TerminalStyle(foreground: .yellow, background: .blue)
        )

        label.render(in: &canvas)

        XCTAssertEqual(canvas[2, 1].character, "H")
        XCTAssertEqual(canvas[6, 1].character, "o")
        XCTAssertEqual(canvas[2, 1].style.foreground, .yellow)
        XCTAssertEqual(canvas[2, 1].style.background, .blue)
    }

    func testLabelClipsToFrameWidth() {
        var canvas = Canvas(size: TerminalSize(columns: 12, rows: 3))
        let label = Label("Overflow", frame: Rect(x: 0, y: 0, width: 4, height: 1))

        label.render(in: &canvas)

        XCTAssertEqual(String(canvas.rows()[0].prefix(4).map(\.character)), "Over")
        XCTAssertEqual(canvas[4, 0].character, " ")
    }

    func testLabelCentersWithinFrame() {
        var canvas = Canvas(size: TerminalSize(columns: 12, rows: 3))
        let label = Label("Hi", frame: Rect(x: 0, y: 0, width: 6, height: 1), alignment: .center)

        label.render(in: &canvas)

        XCTAssertEqual(canvas[2, 0].character, "H")
        XCTAssertEqual(canvas[3, 0].character, "i")
    }

    func testLabelRightAlignsWithinFrame() {
        var canvas = Canvas(size: TerminalSize(columns: 12, rows: 3))
        let label = Label("Hi", frame: Rect(x: 0, y: 0, width: 6, height: 1), alignment: .right)

        label.render(in: &canvas)

        XCTAssertEqual(canvas[4, 0].character, "H")
        XCTAssertEqual(canvas[5, 0].character, "i")
    }

    func testVerticalStacksChildrenWithSpacing() {
        var canvas = Canvas(size: TerminalSize(columns: 20, rows: 8))
        let vertical = Vertical(
            frame: Rect(x: 2, y: 1, width: 10, height: 5),
            spacing: 1,
            children: [
                AnyCanvasRenderable(Label("One", frame: Rect(x: 0, y: 0, width: 10, height: 1))),
                AnyCanvasRenderable(Label("Two", frame: Rect(x: 0, y: 0, width: 10, height: 1)))
            ]
        )

        vertical.render(in: &canvas)

        XCTAssertEqual(canvas[2, 1].character, "O")
        XCTAssertEqual(canvas[2, 3].character, "T")
    }

    func testVerticalAppliesFillStyle() {
        var canvas = Canvas(size: TerminalSize(columns: 20, rows: 8))
        let vertical = Vertical(
            frame: Rect(x: 2, y: 1, width: 10, height: 5),
            fillStyle: TerminalStyle(foreground: .white, background: .black),
            children: []
        )

        vertical.render(in: &canvas)

        XCTAssertEqual(canvas[2, 1].style.background, .black)
        XCTAssertEqual(canvas[11, 5].style.background, .black)
    }

    func testVerticalClipsChildrenToContainerHeight() {
        var canvas = Canvas(size: TerminalSize(columns: 20, rows: 8))
        let vertical = Vertical(
            frame: Rect(x: 2, y: 1, width: 10, height: 1),
            children: [
                AnyCanvasRenderable(Label("One", frame: Rect(x: 0, y: 0, width: 10, height: 1))),
                AnyCanvasRenderable(Label("Two", frame: Rect(x: 0, y: 0, width: 10, height: 1)))
            ]
        )

        vertical.render(in: &canvas)

        XCTAssertEqual(canvas[2, 1].character, "O")
        XCTAssertEqual(canvas[2, 2].character, " ")
    }

    func testMainViewCanFocusAndActivateButtonWithKeyboard() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertEqual(view.handle(.key(.tab)), .none)
        XCTAssertEqual(view.focusedControl, .button)
        XCTAssertEqual(view.handle(.key(.enter)), .quit)
    }

    func testMainViewCanActivateButtonWithMouse() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 4, y: 6), pressed: true))), .quit)
    }

    func testDemoRendersMultipleLabelStyles() {
        let view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        let canvas = view.render(size: TerminalSize(columns: 80, rows: 20))

        XCTAssertEqual(canvas[2, 9].character, "L")
        XCTAssertEqual(canvas[27, 9].character, "C")
        XCTAssertEqual(canvas[55, 9].character, "R")
        XCTAssertEqual(canvas[27, 9].style.background, .cyan)
        XCTAssertEqual(canvas[55, 9].style.foreground, .yellow)
    }

    func testDemoRendersMultipleButtonStates() {
        let view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        let canvas = view.render(size: TerminalSize(columns: 80, rows: 20))

        XCTAssertEqual(canvas[6, 11].character, "N")
        XCTAssertEqual(canvas[21, 11].character, "F")
        XCTAssertEqual(canvas[37, 11].character, "D")
        XCTAssertEqual(canvas[6, 11].style.background, .brightWhite)
        XCTAssertEqual(canvas[21, 11].style.background, .blue)
        XCTAssertEqual(canvas[37, 11].style.background, .brightBlack)
    }

    func testDemoRendersVerticalContainerExample() {
        let view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        let canvas = view.render(size: TerminalSize(columns: 80, rows: 24))

        XCTAssertEqual(canvas[10, 14].character, "V")
        XCTAssertEqual(canvas[2, 16].character, "C")
        XCTAssertEqual(canvas[4, 18].character, "C")
        XCTAssertEqual(canvas[2, 14].style.background, .black)
    }
}

private final class ActionRecorder: @unchecked Sendable {
    private(set) var count = 0

    func activate() {
        count += 1
    }
}

private final class VirtualTerminalDevice: TerminalDevice, @unchecked Sendable {
    var output = ""
    private let terminalSize: TerminalSize

    init(size: TerminalSize) {
        self.terminalSize = size
    }

    func readInput(maxBytes: Int) throws -> [UInt8] {
        []
    }

    func writeOutput(_ output: String) throws {
        self.output += output
    }

    func size() -> TerminalSize {
        terminalSize
    }

    func enableRawMode() throws {}

    func restoreMode() {}
}
