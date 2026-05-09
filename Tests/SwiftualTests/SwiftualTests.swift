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

    func testMenuMouseRoutingWorksAfterOtherControlHasFocus() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        _ = view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 58, y: 19), pressed: true)))
        XCTAssertEqual(view.focusedControl, .progressButton)

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 1, y: 0), pressed: true))), .none)
        XCTAssertEqual(view.focusedControl, .menuBar)
        XCTAssertTrue(view.menuBar.isOpen)
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

    func testANSIBackendEnablesAndDisablesMouseDragTracking() throws {
        let device = VirtualTerminalDevice(size: TerminalSize(columns: 6, rows: 2))
        let backend = ANSITerminalBackend()

        try backend.enterApplicationMode(device: device)
        try backend.exitApplicationMode(device: device)

        XCTAssertTrue(device.output.contains("\u{001B}[?1002h"))
        XCTAssertTrue(device.output.contains("\u{001B}[?1002l"))
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

    func testButtonUsesPureSwiftStateStyles() {
        var normal = Button(
            "Run",
            frame: Rect(x: 0, y: 0, width: 8, height: 1),
            style: TerminalStyle(foreground: .yellow, background: .red),
            focusedStyle: TerminalStyle(foreground: .cyan, background: .green, bold: true),
            disabledStyle: TerminalStyle(foreground: .white, background: .black)
        )
        var canvas = Canvas(size: TerminalSize(columns: 10, rows: 3))

        normal.render(in: &canvas)
        XCTAssertEqual(canvas[0, 0].style.background, .red)
        XCTAssertEqual(canvas[0, 0].style.foreground, .yellow)

        normal.isFocused = true
        normal.render(in: &canvas)
        XCTAssertEqual(canvas[0, 0].style.background, .green)
        XCTAssertEqual(canvas[0, 0].style.foreground, .cyan)
        XCTAssertTrue(canvas[0, 0].style.bold)

        normal.isEnabled = false
        normal.render(in: &canvas)
        XCTAssertEqual(canvas[0, 0].style.background, .black)
        XCTAssertEqual(canvas[0, 0].style.foreground, .white)
    }

    func testButtonPreservesOneRowRenderingWithCustomStyles() {
        let button = Button(
            "Wide",
            frame: Rect(x: 0, y: 1, width: 12, height: 1),
            style: TerminalStyle(foreground: .black, background: .cyan)
        )
        var canvas = Canvas(size: TerminalSize(columns: 14, rows: 3))

        button.render(in: &canvas)

        XCTAssertEqual(canvas[0, 1].style.background, .cyan)
        XCTAssertEqual(canvas[4, 1].character, "W")
        XCTAssertEqual(canvas[7, 1].character, "e")
        XCTAssertEqual(canvas[4, 0].character, " ")
        XCTAssertEqual(canvas[4, 2].character, " ")
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

    func testHorizontalPlacesChildrenWithSpacing() {
        var canvas = Canvas(size: TerminalSize(columns: 24, rows: 4))
        let horizontal = Horizontal(
            frame: Rect(x: 2, y: 1, width: 18, height: 1),
            spacing: 2,
            children: [
                AnyCanvasRenderable(Label("One", frame: Rect(x: 0, y: 0, width: 3, height: 1))),
                AnyCanvasRenderable(Label("Two", frame: Rect(x: 0, y: 0, width: 3, height: 1)))
            ]
        )

        horizontal.render(in: &canvas)

        XCTAssertEqual(canvas[2, 1].character, "O")
        XCTAssertEqual(canvas[7, 1].character, "T")
    }

    func testHorizontalAppliesFillStyle() {
        var canvas = Canvas(size: TerminalSize(columns: 24, rows: 4))
        let horizontal = Horizontal(
            frame: Rect(x: 2, y: 1, width: 18, height: 2),
            fillStyle: TerminalStyle(foreground: .white, background: .black),
            children: []
        )

        horizontal.render(in: &canvas)

        XCTAssertEqual(canvas[2, 1].style.background, .black)
        XCTAssertEqual(canvas[19, 2].style.background, .black)
    }

    func testHorizontalClipsChildrenToContainerWidth() {
        var canvas = Canvas(size: TerminalSize(columns: 24, rows: 4))
        let horizontal = Horizontal(
            frame: Rect(x: 2, y: 1, width: 4, height: 1),
            children: [
                AnyCanvasRenderable(Label("Overflow", frame: Rect(x: 0, y: 0, width: 8, height: 1))),
                AnyCanvasRenderable(Label("Two", frame: Rect(x: 0, y: 0, width: 3, height: 1)))
            ]
        )

        horizontal.render(in: &canvas)

        XCTAssertEqual(canvas[2, 1].character, "O")
        XCTAssertEqual(canvas[5, 1].character, "r")
        XCTAssertEqual(canvas[6, 1].character, " ")
    }

    func testTextInputRendersPlaceholderWhenUnfocusedAndEmpty() {
        var canvas = Canvas(size: TerminalSize(columns: 24, rows: 4))
        let input = TextInput(placeholder: "Name", frame: Rect(x: 2, y: 1, width: 10, height: 1))

        input.render(in: &canvas)

        XCTAssertEqual(canvas[3, 1].character, "N")
        XCTAssertEqual(canvas[3, 1].style.foreground, .white)
        XCTAssertEqual(canvas[3, 1].style.background, .black)
    }

    func testTextInputInsertsCharactersWhenFocused() {
        var input = TextInput(text: "Hi", frame: Rect(x: 0, y: 0, width: 10, height: 1), isFocused: true)

        XCTAssertEqual(input.handle(.key(.character("!"))), .changed("Hi!"))
        XCTAssertEqual(input.text, "Hi!")
        XCTAssertEqual(input.cursorIndex, 3)
    }

    func testTextInputBackspaceRemovesCharacterBeforeCursor() {
        var input = TextInput(text: "H!", frame: Rect(x: 0, y: 0, width: 10, height: 1), cursorIndex: 2, isFocused: true)

        XCTAssertEqual(input.handle(.key(.backspace)), .changed("H"))
        XCTAssertEqual(input.text, "H")
        XCTAssertEqual(input.cursorIndex, 1)
    }

    func testTextInputMovesCursorLeftAndRight() {
        var input = TextInput(text: "Hello", frame: Rect(x: 0, y: 0, width: 10, height: 1), cursorIndex: 3, isFocused: true)

        XCTAssertEqual(input.handle(.key(.left)), .cursorMoved(2))
        XCTAssertEqual(input.cursorIndex, 2)
        XCTAssertEqual(input.handle(.key(.right)), .cursorMoved(3))
        XCTAssertEqual(input.cursorIndex, 3)
    }

    func testTextInputSubmitsOnEnter() {
        var input = TextInput(text: "Hello", frame: Rect(x: 0, y: 0, width: 10, height: 1), isFocused: true)

        XCTAssertEqual(input.handle(.key(.enter)), .submitted("Hello"))
    }

    func testTextInputMouseClickFocusesAndMovesCursor() {
        var input = TextInput(text: "Hello", frame: Rect(x: 2, y: 1, width: 10, height: 1))

        XCTAssertEqual(input.handle(.mouse(MouseEvent(button: .left, location: Point(x: 5, y: 1), pressed: true))), .focused)
        XCTAssertTrue(input.isFocused)
        XCTAssertEqual(input.cursorIndex, 2)
    }

    func testTextInputScrollsHorizontallyToKeepCursorVisibleAtEnd() {
        var canvas = Canvas(size: TerminalSize(columns: 16, rows: 3))
        let input = TextInput(text: "abcdef", frame: Rect(x: 0, y: 0, width: 5, height: 1), cursorIndex: 6, isFocused: true)

        input.render(in: &canvas)

        XCTAssertEqual(canvas[1, 0].character, "e")
        XCTAssertEqual(canvas[2, 0].character, "f")
        XCTAssertEqual(canvas[3, 0].character, " ")
        XCTAssertEqual(canvas[3, 0].style.background, .brightWhite)
    }

    func testTextInputScrollsBackWhenCursorMovesLeft() {
        var canvas = Canvas(size: TerminalSize(columns: 16, rows: 3))
        let input = TextInput(text: "abcdef", frame: Rect(x: 0, y: 0, width: 5, height: 1), cursorIndex: 2, isFocused: true)

        input.render(in: &canvas)

        XCTAssertEqual(canvas[1, 0].character, "a")
        XCTAssertEqual(canvas[2, 0].character, "b")
        XCTAssertEqual(canvas[3, 0].character, "c")
        XCTAssertEqual(canvas[3, 0].style.background, .brightWhite)
    }

    func testTextInputBlockCursorHighlightsCurrentCharacterWhileBackingUp() {
        var canvas = Canvas(size: TerminalSize(columns: 32, rows: 3))
        let input = TextInput(text: "Johnny five is alive", frame: Rect(x: 0, y: 0, width: 24, height: 1), cursorIndex: 17, isFocused: true)

        input.render(in: &canvas)

        XCTAssertEqual(canvas[18, 0].character, "i")
        XCTAssertEqual(canvas[18, 0].style.background, .brightWhite)
    }

    func testTextInputLeftFromEndHighlightsLastCharacter() {
        var input = TextInput(text: "alive", frame: Rect(x: 0, y: 0, width: 10, height: 1), cursorIndex: 5, isFocused: true)
        var canvas = Canvas(size: TerminalSize(columns: 16, rows: 3))

        XCTAssertEqual(input.handle(.key(.left)), .cursorMoved(4))
        input.render(in: &canvas)

        XCTAssertEqual(canvas[5, 0].character, "e")
        XCTAssertEqual(canvas[5, 0].style.background, .brightWhite)
    }

    func testInputParserSplitsRepeatedArrowSequences() {
        let events = InputParser().parse(Array("\u{1B}[D\u{1B}[D\u{1B}[C".utf8))

        XCTAssertEqual(events, [.key(.left), .key(.left), .key(.right)])
    }

    func testInputParserHandlesAlternateAndModifiedArrowSequences() {
        XCTAssertEqual(InputParser().parse(Array("\u{1B}OD".utf8)), [.key(.left)])
        XCTAssertEqual(InputParser().parse(Array("\u{1B}OC".utf8)), [.key(.right)])
        XCTAssertEqual(InputParser().parse(Array("\u{1B}[1;2D".utf8)), [.key(.left)])
        XCTAssertEqual(InputParser().parse(Array("\u{1B}[1;2C".utf8)), [.key(.right)])
    }

    func testTextInputRepeatedLeftAndRightSequencesMoveOneStepEach() {
        var input = TextInput(text: "alive", frame: Rect(x: 0, y: 0, width: 10, height: 1), cursorIndex: 5, isFocused: true)
        let events = InputParser().parse(Array("\u{1B}[D\u{1B}[D\u{1B}[C".utf8))

        for event in events {
            _ = input.handle(event)
        }

        XCTAssertEqual(input.cursorIndex, 4)
    }

    func testCheckboxRendersUncheckedState() {
        var canvas = Canvas(size: TerminalSize(columns: 24, rows: 3))
        let checkbox = Checkbox("Agree", frame: Rect(x: 2, y: 1, width: 12, height: 1))

        checkbox.render(in: &canvas)

        XCTAssertEqual(canvas[2, 1].character, "[")
        XCTAssertEqual(canvas[3, 1].character, " ")
        XCTAssertEqual(canvas[4, 1].character, "]")
        XCTAssertEqual(canvas[6, 1].character, "A")
    }

    func testCheckboxRendersCheckedState() {
        var canvas = Canvas(size: TerminalSize(columns: 24, rows: 3))
        let checkbox = Checkbox("Agree", frame: Rect(x: 2, y: 1, width: 12, height: 1), isChecked: true)

        checkbox.render(in: &canvas)

        XCTAssertEqual(canvas[3, 1].character, "x")
    }

    func testCheckboxTogglesWithKeyboardWhenFocused() {
        var checkbox = Checkbox("Agree", frame: Rect(x: 0, y: 0, width: 12, height: 1), isFocused: true)

        XCTAssertEqual(checkbox.handle(.key(.character(" "))), .changed(true))
        XCTAssertTrue(checkbox.isChecked)
        XCTAssertEqual(checkbox.handle(.key(.enter)), .changed(false))
        XCTAssertFalse(checkbox.isChecked)
    }

    func testCheckboxIgnoresKeyboardWhenUnfocused() {
        var checkbox = Checkbox("Agree", frame: Rect(x: 0, y: 0, width: 12, height: 1), isFocused: false)

        XCTAssertEqual(checkbox.handle(.key(.character(" "))), .none)
        XCTAssertFalse(checkbox.isChecked)
    }

    func testCheckboxTogglesWithMouseInsideFrame() {
        var checkbox = Checkbox("Agree", frame: Rect(x: 2, y: 1, width: 12, height: 1))

        XCTAssertEqual(checkbox.handle(.mouse(MouseEvent(button: .left, location: Point(x: 3, y: 1), pressed: true))), .changed(true))
        XCTAssertTrue(checkbox.isChecked)
        XCTAssertTrue(checkbox.isFocused)
    }

    func testCheckboxDisabledDoesNotToggle() {
        var checkbox = Checkbox("Agree", frame: Rect(x: 0, y: 0, width: 12, height: 1), isFocused: true, isEnabled: false)

        XCTAssertEqual(checkbox.handle(.key(.enter)), .none)
        XCTAssertFalse(checkbox.isChecked)
    }

    func testSwitchRendersOffState() {
        var canvas = Canvas(size: TerminalSize(columns: 24, rows: 3))
        let toggle = Switch("Power", frame: Rect(x: 2, y: 1, width: 14, height: 1))

        toggle.render(in: &canvas)

        XCTAssertEqual(canvas[2, 1].character, "<")
        XCTAssertEqual(canvas[3, 1].character, "O")
        XCTAssertEqual(canvas[5, 1].character, "F")
        XCTAssertEqual(canvas[8, 1].character, "P")
    }

    func testSwitchRendersOnState() {
        var canvas = Canvas(size: TerminalSize(columns: 24, rows: 3))
        let toggle = Switch("Power", frame: Rect(x: 2, y: 1, width: 14, height: 1), isOn: true)

        toggle.render(in: &canvas)

        XCTAssertEqual(canvas[3, 1].character, "O")
        XCTAssertEqual(canvas[4, 1].character, "N")
        XCTAssertEqual(canvas[2, 1].style.background, .green)
    }

    func testSwitchTogglesWithKeyboardWhenFocused() {
        var toggle = Switch("Power", frame: Rect(x: 0, y: 0, width: 14, height: 1), isFocused: true)

        XCTAssertEqual(toggle.handle(.key(.character(" "))), .changed(true))
        XCTAssertTrue(toggle.isOn)
        XCTAssertEqual(toggle.handle(.key(.enter)), .changed(false))
        XCTAssertFalse(toggle.isOn)
    }

    func testSwitchIgnoresKeyboardWhenUnfocused() {
        var toggle = Switch("Power", frame: Rect(x: 0, y: 0, width: 14, height: 1), isFocused: false)

        XCTAssertEqual(toggle.handle(.key(.character(" "))), .none)
        XCTAssertFalse(toggle.isOn)
    }

    func testSwitchTogglesWithMouseInsideFrame() {
        var toggle = Switch("Power", frame: Rect(x: 2, y: 1, width: 14, height: 1))

        XCTAssertEqual(toggle.handle(.mouse(MouseEvent(button: .left, location: Point(x: 3, y: 1), pressed: true))), .changed(true))
        XCTAssertTrue(toggle.isOn)
        XCTAssertTrue(toggle.isFocused)
    }

    func testFocusedSwitchKeepsOnStateColor() {
        var canvas = Canvas(size: TerminalSize(columns: 24, rows: 3))
        let toggle = Switch("Power", frame: Rect(x: 2, y: 1, width: 14, height: 1), isOn: true, isFocused: true)

        toggle.render(in: &canvas)

        XCTAssertEqual(canvas[2, 1].style.background, .green)
        XCTAssertEqual(canvas[2, 1].style.foreground, .brightWhite)
        XCTAssertEqual(canvas[2, 1].style.bold, true)
        XCTAssertEqual(canvas[2, 1].style.inverse, false)
    }

    func testFocusedSwitchUsesOffFocusColorWhenOff() {
        var canvas = Canvas(size: TerminalSize(columns: 24, rows: 3))
        let toggle = Switch("Power", frame: Rect(x: 2, y: 1, width: 14, height: 1), isOn: false, isFocused: true)

        toggle.render(in: &canvas)

        XCTAssertEqual(canvas[2, 1].style.background, .blue)
    }

    func testSwitchDisabledDoesNotToggle() {
        var toggle = Switch("Power", frame: Rect(x: 0, y: 0, width: 14, height: 1), isFocused: true, isEnabled: false)

        XCTAssertEqual(toggle.handle(.key(.enter)), .none)
        XCTAssertFalse(toggle.isOn)
    }

    func testSelectRendersClosedState() {
        var canvas = Canvas(size: TerminalSize(columns: 32, rows: 6))
        let select = Select(frame: Rect(x: 2, y: 1, width: 12, height: 1), options: [SelectOption("Alpha"), SelectOption("Beta")])

        select.render(in: &canvas)

        XCTAssertEqual(canvas[3, 1].character, "A")
        XCTAssertEqual(canvas[9, 1].character, "v")
    }

    func testSelectRendersOpenOptions() {
        var canvas = Canvas(size: TerminalSize(columns: 32, rows: 6))
        var select = Select(frame: Rect(x: 2, y: 1, width: 12, height: 1), options: [SelectOption("Alpha"), SelectOption("Beta")], isFocused: true)
        _ = select.handle(.key(.down))

        select.render(in: &canvas)

        XCTAssertEqual(canvas[3, 2].character, "A")
        XCTAssertEqual(canvas[3, 3].character, "B")
        XCTAssertEqual(canvas[2, 2].style.background, .blue)
    }

    func testSelectKeyboardNavigationAndSelection() {
        var select = Select(frame: Rect(x: 0, y: 0, width: 12, height: 1), options: [SelectOption("Alpha"), SelectOption("Beta"), SelectOption("Gamma")], isFocused: true)

        XCTAssertEqual(select.handle(.key(.down)), .opened)
        XCTAssertEqual(select.handle(.key(.down)), .highlighted(1))
        XCTAssertEqual(select.handle(.key(.enter)), .changed(1, "Beta"))
        XCTAssertEqual(select.selectedIndex, 1)
        XCTAssertFalse(select.isOpen)
    }

    func testSelectSkipsDisabledOptions() {
        var select = Select(frame: Rect(x: 0, y: 0, width: 12, height: 1), options: [SelectOption("Alpha"), SelectOption("Beta", isEnabled: false), SelectOption("Gamma")], isFocused: true)

        XCTAssertEqual(select.handle(.key(.down)), .opened)
        XCTAssertEqual(select.handle(.key(.down)), .highlighted(2))
        XCTAssertEqual(select.highlightedIndex, 2)
    }

    func testSelectEscapeClosesWithoutChangingSelection() {
        var select = Select(frame: Rect(x: 0, y: 0, width: 12, height: 1), options: [SelectOption("Alpha"), SelectOption("Beta")], isFocused: true)

        _ = select.handle(.key(.down))
        _ = select.handle(.key(.down))
        XCTAssertEqual(select.handle(.key(.escape)), .closed)
        XCTAssertEqual(select.selectedIndex, 0)
        XCTAssertFalse(select.isOpen)
    }

    func testSelectMouseOpensAndSelectsOption() {
        var select = Select(frame: Rect(x: 2, y: 1, width: 12, height: 1), options: [SelectOption("Alpha"), SelectOption("Beta")])

        XCTAssertEqual(select.handle(.mouse(MouseEvent(button: .left, location: Point(x: 3, y: 1), pressed: true))), .opened)
        XCTAssertTrue(select.isOpen)
        XCTAssertEqual(select.handle(.mouse(MouseEvent(button: .left, location: Point(x: 3, y: 3), pressed: true))), .changed(1, "Beta"))
        XCTAssertEqual(select.selectedIndex, 1)
    }

    func testScrollViewRendersVisibleRowsAndClipsContent() {
        var canvas = Canvas(size: TerminalSize(columns: 30, rows: 8))
        let scrollView = ScrollView(frame: Rect(x: 2, y: 1, width: 12, height: 3), content: ["One", "Two", "Three", "Four"])

        scrollView.render(in: &canvas)

        XCTAssertEqual(canvas[2, 1].character, "O")
        XCTAssertEqual(canvas[2, 2].character, "T")
        XCTAssertEqual(canvas[2, 3].character, "T")
        XCTAssertEqual(canvas[2, 4].character, " ")
    }

    func testScrollViewKeyboardScrollsWhenFocused() {
        var scrollView = ScrollView(frame: Rect(x: 0, y: 0, width: 12, height: 3), content: ["One", "Two", "Three", "Four"], isFocused: true)

        XCTAssertEqual(scrollView.handle(.key(.down)), .scrolled(1))
        XCTAssertEqual(scrollView.scrollOffset, 1)
        XCTAssertEqual(scrollView.handle(.key(.up)), .scrolled(0))
        XCTAssertEqual(scrollView.scrollOffset, 0)
    }

    func testScrollViewMouseWheelScrollsInsideFrame() {
        var scrollView = ScrollView(frame: Rect(x: 2, y: 1, width: 12, height: 3), content: ["One", "Two", "Three", "Four"])

        XCTAssertEqual(scrollView.handle(.mouse(MouseEvent(button: .scrollDown, location: Point(x: 3, y: 2), pressed: true))), .scrolled(1))
        XCTAssertEqual(scrollView.scrollOffset, 1)
        XCTAssertEqual(scrollView.handle(.mouse(MouseEvent(button: .scrollUp, location: Point(x: 3, y: 2), pressed: true))), .scrolled(0))
        XCTAssertEqual(scrollView.scrollOffset, 0)
    }

    func testScrollViewScrollbarDragSetsScrollOffset() {
        var scrollView = ScrollView(frame: Rect(x: 2, y: 1, width: 12, height: 4), content: ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight"])

        XCTAssertEqual(scrollView.handle(.mouse(MouseEvent(button: .left, location: Point(x: 13, y: 4), pressed: true))), .scrolled(4))
        XCTAssertEqual(scrollView.scrollOffset, 4)
        XCTAssertTrue(scrollView.isFocused)
    }

    func testScrollViewScrollbarDragClampsToTopAndBottom() {
        var scrollView = ScrollView(frame: Rect(x: 2, y: 1, width: 12, height: 4), content: ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight"])

        _ = scrollView.handle(.mouse(MouseEvent(button: .left, location: Point(x: 13, y: 99), pressed: true)))
        XCTAssertEqual(scrollView.scrollOffset, 4)
        _ = scrollView.handle(.mouse(MouseEvent(button: .left, location: Point(x: 13, y: -5), pressed: true)))
        XCTAssertEqual(scrollView.scrollOffset, 0)
    }

    func testProgressBarRendersDeterminateFill() {
        var canvas = Canvas(size: TerminalSize(columns: 20, rows: 3))
        let progressBar = ProgressBar(frame: Rect(x: 2, y: 1, width: 10, height: 1), value: 0.4, showPercentage: false)

        progressBar.render(in: &canvas)

        XCTAssertEqual(canvas[2, 1].style.background, .green)
        XCTAssertEqual(canvas[5, 1].style.background, .green)
        XCTAssertEqual(canvas[6, 1].style.background, .black)
    }

    func testProgressBarClampsValuesToRange() {
        XCTAssertEqual(ProgressBar(frame: Rect(x: 0, y: 0, width: 10, height: 1), value: -10, range: 0...100).fractionComplete, 0)
        XCTAssertEqual(ProgressBar(frame: Rect(x: 0, y: 0, width: 10, height: 1), value: 150, range: 0...100).fractionComplete, 1)
        XCTAssertEqual(ProgressBar(frame: Rect(x: 0, y: 0, width: 10, height: 1), value: 25, range: 0...100).fractionComplete, 0.25)
    }

    func testProgressBarRendersLabelAndPercentage() {
        var canvas = Canvas(size: TerminalSize(columns: 30, rows: 3))
        let progressBar = ProgressBar(frame: Rect(x: 2, y: 1, width: 20, height: 1), value: 0.65, label: "Load")

        progressBar.render(in: &canvas)

        XCTAssertEqual(canvas[8, 1].character, "L")
        XCTAssertEqual(canvas[13, 1].character, "6")
        XCTAssertEqual(canvas[15, 1].character, "%")
        XCTAssertEqual(canvas[8, 1].style.background, .green)
        XCTAssertEqual(canvas[15, 1].style.background, .black)
    }

    func testProgressBarRendersIndeterminatePulse() {
        var canvas = Canvas(size: TerminalSize(columns: 20, rows: 3))
        let progressBar = ProgressBar(frame: Rect(x: 2, y: 1, width: 8, height: 1), value: nil, pulseOffset: 4)

        progressBar.render(in: &canvas)

        XCTAssertEqual(canvas[4, 1].style.background, .cyan)
        XCTAssertEqual(canvas[5, 1].style.background, .cyan)
        XCTAssertEqual(canvas[6, 1].style.background, .black)
    }

    func testRichLogAppendsAndTrimsEntries() {
        var richLog = RichLog(frame: Rect(x: 0, y: 0, width: 20, height: 3), maxEntries: 2)

        richLog.append("One")
        richLog.append("Two")
        richLog.append("Three")

        XCTAssertEqual(richLog.entries.map(\.message), ["Two", "Three"])
    }

    func testRichLogRendersTitleAndLatestEntries() {
        var canvas = Canvas(size: TerminalSize(columns: 30, rows: 5))
        let richLog = RichLog(
            frame: Rect(x: 2, y: 1, width: 20, height: 3),
            entries: [
                RichLogEntry("First"),
                RichLogEntry("Second", style: TerminalStyle(foreground: .green, background: .black, bold: true)),
                RichLogEntry("Third")
            ]
        )

        richLog.render(in: &canvas)

        XCTAssertEqual(canvas[3, 1].character, "R")
        XCTAssertEqual(canvas[2, 2].character, "S")
        XCTAssertEqual(canvas[2, 3].character, "T")
        XCTAssertEqual(canvas[2, 2].style.foreground, .green)
    }

    func testDataTableRendersHeaderRowsAndSelection() {
        var canvas = Canvas(size: TerminalSize(columns: 40, rows: 8))
        let table = DataTable(
            frame: Rect(x: 2, y: 1, width: 24, height: 4),
            columns: [DataTableColumn("Name", width: 10), DataTableColumn("State", width: 10)],
            rows: [["Menu", "Ready"], ["Table", "New"]],
            selectedRowIndex: 1,
            isFocused: true
        )

        table.render(in: &canvas)

        XCTAssertEqual(canvas[3, 1].character, "N")
        XCTAssertEqual(canvas[12, 1].character, "|")
        XCTAssertEqual(canvas[12, 1].style.background, .cyan)
        XCTAssertEqual(canvas[3, 2].character, "M")
        XCTAssertEqual(canvas[3, 3].character, "T")
        XCTAssertEqual(canvas[3, 3].style.background, .blue)
        XCTAssertEqual(canvas[12, 3].style.background, .blue)
        XCTAssertTrue(canvas[3, 3].style.bold)
    }

    func testDataTableKeyboardSelectionAndActivation() {
        var table = DataTable(
            frame: Rect(x: 0, y: 0, width: 24, height: 3),
            columns: [DataTableColumn("Name", width: 10), DataTableColumn("State", width: 10)],
            rows: [["Menu", "Ready"], ["Button", "Ready"], ["Table", "New"]],
            isFocused: true
        )

        XCTAssertEqual(table.handle(.key(.down)), .selected(1, ["Button", "Ready"]))
        XCTAssertEqual(table.handle(.key(.enter)), .activated(1, ["Button", "Ready"]))
        XCTAssertEqual(table.scrollOffset, 0)
        XCTAssertEqual(table.handle(.key(.down)), .selected(2, ["Table", "New"]))
        XCTAssertEqual(table.scrollOffset, 1)
    }

    func testDataTableMouseSelection() {
        var table = DataTable(
            frame: Rect(x: 2, y: 1, width: 24, height: 4),
            columns: [DataTableColumn("Name", width: 10), DataTableColumn("State", width: 10)],
            rows: [["Menu", "Ready"], ["Button", "Ready"], ["Table", "New"]]
        )

        XCTAssertEqual(table.handle(.mouse(MouseEvent(button: .left, location: Point(x: 3, y: 3), pressed: true))), .selected(1, ["Button", "Ready"]))
        XCTAssertTrue(table.isFocused)
        XCTAssertEqual(table.selectedRowIndex, 1)
    }

    func testTreeRendersExpandedRowsAndSelection() {
        var canvas = Canvas(size: TerminalSize(columns: 40, rows: 8))
        let tree = Tree(
            frame: Rect(x: 2, y: 1, width: 24, height: 5),
            roots: [
                TreeNode("Root", children: [
                    TreeNode("Child"),
                    TreeNode("Folder", isExpanded: false, children: [TreeNode("Hidden")])
                ])
            ],
            selectedPath: [0, 1],
            isFocused: true
        )

        tree.render(in: &canvas)

        XCTAssertEqual(canvas[2, 1].character, "v")
        XCTAssertEqual(canvas[4, 1].character, "R")
        XCTAssertEqual(canvas[4, 2].character, "-")
        XCTAssertEqual(canvas[6, 2].character, "C")
        XCTAssertEqual(canvas[4, 3].character, ">")
        XCTAssertEqual(canvas[6, 3].character, "F")
        XCTAssertEqual(canvas[4, 3].style.background, .blue)
        XCTAssertTrue(canvas[4, 3].style.bold)
    }

    func testTreeKeyboardSelectionExpansionAndActivation() {
        var tree = Tree(
            frame: Rect(x: 0, y: 0, width: 24, height: 3),
            roots: [
                TreeNode("Root", children: [
                    TreeNode("Child"),
                    TreeNode("Folder", isExpanded: false, children: [TreeNode("Grandchild")])
                ])
            ],
            isFocused: true
        )

        XCTAssertEqual(tree.handle(.key(.down)), .selected(TreeRow(path: [0, 0], title: "Child", depth: 1, isExpanded: true, hasChildren: false)))
        XCTAssertEqual(tree.handle(.key(.down)), .selected(TreeRow(path: [0, 1], title: "Folder", depth: 1, isExpanded: false, hasChildren: true)))
        XCTAssertEqual(tree.handle(.key(.right)), .expanded(TreeRow(path: [0, 1], title: "Folder", depth: 1, isExpanded: true, hasChildren: true)))
        XCTAssertEqual(tree.handle(.key(.down)), .selected(TreeRow(path: [0, 1, 0], title: "Grandchild", depth: 2, isExpanded: true, hasChildren: false)))
        XCTAssertEqual(tree.handle(.key(.enter)), .activated(TreeRow(path: [0, 1, 0], title: "Grandchild", depth: 2, isExpanded: true, hasChildren: false)))
    }

    func testTreeMouseSelectionAndToggle() {
        var tree = Tree(
            frame: Rect(x: 2, y: 1, width: 24, height: 5),
            roots: [
                TreeNode("Root", children: [
                    TreeNode("Folder", children: [TreeNode("Grandchild")])
                ])
            ]
        )

        XCTAssertEqual(tree.handle(.mouse(MouseEvent(button: .left, location: Point(x: 3, y: 2), pressed: true))), .collapsed(TreeRow(path: [0, 0], title: "Folder", depth: 1, isExpanded: false, hasChildren: true)))
        XCTAssertTrue(tree.isFocused)
        XCTAssertEqual(tree.visibleRows.count, 2)
    }

    func testTreeRendersScrollbarWhenContentOverflows() {
        var canvas = Canvas(size: TerminalSize(columns: 40, rows: 8))
        let tree = Tree(
            frame: Rect(x: 2, y: 1, width: 12, height: 3),
            roots: [
                TreeNode("Root", children: (1...6).map { TreeNode("Child \($0)") })
            ]
        )

        tree.render(in: &canvas)

        XCTAssertEqual(canvas[12, 1].style.background, .blue)
        XCTAssertEqual(canvas[13, 1].style.background, .blue)
        XCTAssertEqual(canvas[12, 2].style.background, .brightBlack)
        XCTAssertEqual(canvas[13, 2].style.background, .brightBlack)
        XCTAssertEqual(canvas[11, 1].character, " ")
    }

    func testTreeMouseWheelScrollsInsideFrame() {
        var tree = Tree(
            frame: Rect(x: 2, y: 1, width: 12, height: 3),
            roots: [
                TreeNode("Root", children: (1...6).map { TreeNode("Child \($0)") })
            ]
        )

        XCTAssertEqual(tree.handle(.mouse(MouseEvent(button: .scrollDown, location: Point(x: 3, y: 2), pressed: true))), .scrolled(1))
        XCTAssertEqual(tree.scrollOffset, 1)
        XCTAssertEqual(tree.handle(.mouse(MouseEvent(button: .scrollUp, location: Point(x: 3, y: 2), pressed: true))), .scrolled(0))
        XCTAssertEqual(tree.scrollOffset, 0)
    }

    func testTreeScrollbarDragSetsScrollOffset() {
        var tree = Tree(
            frame: Rect(x: 2, y: 1, width: 12, height: 3),
            roots: [
                TreeNode("Root", children: (1...6).map { TreeNode("Child \($0)") })
            ]
        )

        XCTAssertEqual(tree.handle(.mouse(MouseEvent(button: .left, location: Point(x: 12, y: 3), pressed: true))), .scrolled(4))
        XCTAssertEqual(tree.scrollOffset, 4)
        XCTAssertTrue(tree.isFocused)
    }

    func testModalRendersWhenPresented() {
        var canvas = Canvas(size: TerminalSize(columns: 80, rows: 24))
        let modal = Modal(frame: Rect(x: 10, y: 5, width: 30, height: 8), title: "Title", message: "Hello", isPresented: true)

        modal.render(in: &canvas)

        XCTAssertEqual(canvas[10, 5].style.background, .blue)
        XCTAssertEqual(canvas[22, 5].character, "T")
        XCTAssertEqual(canvas[12, 7].character, "H")
        XCTAssertEqual(canvas[14, 11].character, "O")
    }

    func testModalPreservesBackgroundOutsidePanelByDefault() {
        var canvas = Canvas(size: TerminalSize(columns: 20, rows: 8), fill: Cell(".", style: TerminalStyle(foreground: .yellow, background: .blue)))
        let modal = Modal(frame: Rect(x: 4, y: 2, width: 10, height: 4), title: "Hi", message: "Body", isPresented: true)

        modal.render(in: &canvas)

        XCTAssertEqual(canvas[0, 0].character, ".")
        XCTAssertEqual(canvas[0, 0].style.background, .blue)
        XCTAssertEqual(canvas[4, 2].style.background, .blue)
    }

    func testModalCanDrawOverlayBackgroundWhenRequested() {
        var canvas = Canvas(size: TerminalSize(columns: 20, rows: 8), fill: Cell(".", style: TerminalStyle(foreground: .yellow, background: .blue)))
        let modal = Modal(frame: Rect(x: 4, y: 2, width: 10, height: 4), title: "Hi", message: "Body", isPresented: true, drawsOverlayBackground: true)

        modal.render(in: &canvas)

        XCTAssertEqual(canvas[0, 0].character, " ")
        XCTAssertEqual(canvas[0, 0].style.background, .brightBlack)
    }

    func testModalEscapeDismisses() {
        var modal = Modal(frame: Rect(x: 10, y: 5, width: 30, height: 8), title: "Title", message: "Hello", isPresented: true)

        XCTAssertEqual(modal.handle(.key(.escape)), .dismissed)
        XCTAssertFalse(modal.isPresented)
    }

    func testModalKeyboardSelectsFocusedButton() {
        var modal = Modal(frame: Rect(x: 10, y: 5, width: 30, height: 8), title: "Title", message: "Hello", buttons: [ModalButton("OK"), ModalButton("Cancel")], isPresented: true)

        XCTAssertEqual(modal.handle(.key(.right)), .highlighted(1))
        XCTAssertEqual(modal.handle(.key(.enter)), .selected(1, "Cancel"))
        XCTAssertFalse(modal.isPresented)
    }

    func testModalMouseSelectsButton() {
        var modal = Modal(frame: Rect(x: 10, y: 5, width: 30, height: 8), title: "Title", message: "Hello", buttons: [ModalButton("OK"), ModalButton("Cancel")], isPresented: true)

        XCTAssertEqual(modal.handle(.mouse(MouseEvent(button: .left, location: Point(x: 20, y: 11), pressed: true))), .selected(1, "Cancel"))
        XCTAssertFalse(modal.isPresented)
    }

    func testModalClickOutsideDismisses() {
        var modal = Modal(frame: Rect(x: 10, y: 5, width: 30, height: 8), title: "Title", message: "Hello", isPresented: true)

        XCTAssertEqual(modal.handle(.mouse(MouseEvent(button: .left, location: Point(x: 2, y: 2), pressed: true))), .dismissed)
        XCTAssertFalse(modal.isPresented)
    }

    func testScrollViewRendersScrollbarWhenContentOverflows() {
        var canvas = Canvas(size: TerminalSize(columns: 30, rows: 8))
        let scrollView = ScrollView(frame: Rect(x: 2, y: 1, width: 12, height: 3), content: ["One", "Two", "Three", "Four", "Five"])

        scrollView.render(in: &canvas)

        XCTAssertEqual(canvas[13, 1].style.background, .blue)
        XCTAssertEqual(canvas[13, 2].style.background, .brightBlack)
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

    func testMainViewCanFocusAndEditTextInputWithKeyboard() {
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
        XCTAssertEqual(view.handle(.key(.tab)), .none)
        XCTAssertEqual(view.focusedControl, .textInput)
        XCTAssertEqual(view.handle(.key(.character("!"))), .none)
        XCTAssertEqual(view.textInput.text, "Swift!")
    }

    func testMainViewCanFocusTextInputWithMouse() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 20, y: 6), pressed: true))), .none)
        XCTAssertEqual(view.focusedControl, .textInput)
    }

    func testMainViewCanFocusAndToggleCheckboxWithKeyboard() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        _ = view.handle(.key(.tab))
        _ = view.handle(.key(.tab))
        _ = view.handle(.key(.tab))
        XCTAssertEqual(view.focusedControl, .checkbox)
        XCTAssertTrue(view.checkbox.isChecked)
        XCTAssertEqual(view.handle(.key(.character(" "))), .none)
        XCTAssertFalse(view.checkbox.isChecked)
    }

    func testMainViewCanFocusAndToggleCheckboxWithMouse() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 47, y: 6), pressed: true))), .none)
        XCTAssertEqual(view.focusedControl, .checkbox)
        XCTAssertFalse(view.checkbox.isChecked)
    }

    func testMainViewCanFocusAndToggleSwitchWithKeyboard() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        _ = view.handle(.key(.tab))
        _ = view.handle(.key(.tab))
        _ = view.handle(.key(.tab))
        _ = view.handle(.key(.tab))
        XCTAssertEqual(view.focusedControl, .switch)
        XCTAssertTrue(view.toggleSwitch.isOn)
        XCTAssertEqual(view.handle(.key(.character(" "))), .none)
        XCTAssertFalse(view.toggleSwitch.isOn)
    }

    func testMainViewCanFocusAndToggleSwitchWithMouse() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 69, y: 6), pressed: true))), .none)
        XCTAssertEqual(view.focusedControl, .switch)
        XCTAssertFalse(view.toggleSwitch.isOn)
    }

    func testMainViewCanFocusAndUseSelectWithKeyboard() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        _ = view.handle(.key(.tab))
        _ = view.handle(.key(.tab))
        _ = view.handle(.key(.tab))
        _ = view.handle(.key(.tab))
        _ = view.handle(.key(.tab))
        XCTAssertEqual(view.focusedControl, .select)
        XCTAssertEqual(view.handle(.key(.down)), .none)
        XCTAssertTrue(view.select.isOpen)
        XCTAssertEqual(view.handle(.key(.down)), .none)
        XCTAssertEqual(view.handle(.key(.enter)), .none)
        XCTAssertEqual(view.select.selectedIndex, 1)
    }

    func testMainViewCanFocusAndUseSelectWithMouse() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 85, y: 6), pressed: true))), .none)
        XCTAssertEqual(view.focusedControl, .select)
        XCTAssertTrue(view.select.isOpen)
        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 85, y: 8), pressed: true))), .none)
        XCTAssertEqual(view.select.selectedIndex, 1)
    }

    func testMainViewCanFocusAndScrollScrollViewWithKeyboard() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        for _ in 0..<6 { _ = view.handle(.key(.tab)) }
        XCTAssertEqual(view.focusedControl, .scrollView)
        XCTAssertEqual(view.handle(.key(.down)), .none)
        XCTAssertEqual(view.scrollView.scrollOffset, 1)
    }

    func testMainViewCanFocusAndScrollScrollViewWithMouseWheel() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .scrollDown, location: Point(x: 75, y: 15), pressed: true))), .none)
        XCTAssertEqual(view.focusedControl, .scrollView)
        XCTAssertEqual(view.scrollView.scrollOffset, 1)
    }

    func testMainViewCanPresentModalWithKeyboard() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        for _ in 0..<7 { _ = view.handle(.key(.tab)) }
        XCTAssertEqual(view.focusedControl, .modalButton)
        XCTAssertEqual(view.handle(.key(.enter)), .none)
        XCTAssertTrue(view.modal.isPresented)
    }

    func testMainViewCanPresentModalWithMouse() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 38, y: 18), pressed: true))), .none)

        XCTAssertTrue(view.modal.isPresented)
        XCTAssertEqual(view.focusedControl, .modalButton)
    }

    func testMainViewCanStartProgressAnimationWithKeyboard() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        for _ in 0..<8 { _ = view.handle(.key(.tab)) }
        XCTAssertEqual(view.focusedControl, .progressButton)
        XCTAssertEqual(view.handle(.key(.enter)), .none)

        XCTAssertNotNil(view.progressAnimationStartedAt)
        XCTAssertEqual(view.progressBar.value, 0)
    }

    func testMainViewCanStartProgressAnimationWithMouse() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 58, y: 19), pressed: true))), .none)

        XCTAssertNotNil(view.progressAnimationStartedAt)
        XCTAssertEqual(view.progressBar.value, 0)
        XCTAssertEqual(view.focusedControl, .progressButton)
    }

    func testMainViewCanFocusAndUseDataTableWithKeyboard() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        for _ in 0..<9 { _ = view.handle(.key(.tab)) }
        XCTAssertEqual(view.focusedControl, .dataTable)
        XCTAssertEqual(view.handle(.key(.down)), .none)
        XCTAssertEqual(view.dataTable.selectedRowIndex, 1)
        XCTAssertTrue(view.richLog.entries.map(\.message).contains("Data table selected row 1: Button / Ready."))
        XCTAssertEqual(view.handle(.key(.enter)), .none)
        XCTAssertTrue(view.richLog.entries.map(\.message).contains("Data table activated row 1: Button / Ready."))
    }

    func testMainViewCanFocusAndUseDataTableWithMouse() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 75, y: 10), pressed: true))), .none)

        XCTAssertEqual(view.focusedControl, .dataTable)
        XCTAssertEqual(view.dataTable.selectedRowIndex, 1)
        XCTAssertTrue(view.richLog.entries.map(\.message).contains("Data table selected row 1: Button / Ready."))
    }

    func testMainViewCanFocusAndUseTreeWithKeyboard() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        for _ in 0..<10 { _ = view.handle(.key(.tab)) }
        XCTAssertEqual(view.focusedControl, .tree)
        XCTAssertEqual(view.handle(.key(.down)), .none)
        XCTAssertTrue(view.richLog.entries.map(\.message).contains("Tree selected: Controls."))
        XCTAssertEqual(view.handle(.key(.left)), .none)
        XCTAssertTrue(view.richLog.entries.map(\.message).contains("Tree collapsed: Controls."))
    }

    func testMainViewCanFocusAndUseTreeWithMouse() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 101, y: 9), pressed: true))), .none)

        XCTAssertEqual(view.focusedControl, .tree)
        XCTAssertTrue(view.richLog.entries.map(\.message).contains("Tree collapsed: Controls."))
    }

    func testCommandPaletteFiltersAndSelectsWithKeyboard() {
        var palette = CommandPalette(
            frame: Rect(x: 2, y: 2, width: 30, height: 8),
            items: [
                CommandPaletteItem("Open file"),
                CommandPaletteItem("Start worker"),
                CommandPaletteItem("Quit")
            ],
            isPresented: true
        )

        XCTAssertEqual(palette.handle(.key(.character("w"))), .queryChanged("w"))
        XCTAssertEqual(palette.filteredItems.map(\.title), ["Start worker"])
        XCTAssertEqual(palette.handle(.key(.enter)), .selected("Start worker"))
        XCTAssertFalse(palette.isPresented)
    }

    func testCommandPaletteMouseSelectsVisibleItem() {
        var palette = CommandPalette(
            frame: Rect(x: 2, y: 2, width: 30, height: 8),
            items: [
                CommandPaletteItem("Open file"),
                CommandPaletteItem("Start worker")
            ],
            isPresented: true
        )

        XCTAssertEqual(palette.handle(.mouse(MouseEvent(button: .left, location: Point(x: 4, y: 7), pressed: true))), .selected("Start worker"))
        XCTAssertFalse(palette.isPresented)
    }

    func testInputParserParsesControlPForCommandPalette() {
        XCTAssertEqual(InputParser().parse([16]), [.key(.controlP)])
    }

    func testMainViewCanOpenAndUseCommandPalette() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertEqual(view.handle(.key(.controlP)), .none)
        XCTAssertTrue(view.commandPalette.isPresented)
        XCTAssertEqual(view.focusedControl, .commandPaletteButton)
        XCTAssertEqual(view.handle(.key(.character("f"))), .none)
        XCTAssertEqual(view.handle(.key(.enter)), .none)
        XCTAssertEqual(view.focusedControl, .tree)
        XCTAssertTrue(view.richLog.entries.map(\.message).contains("Command palette selected: Focus tree."))
    }

    func testMainViewCanStartWorkerWithMouse() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 101, y: 18), pressed: true))), .none)
        XCTAssertEqual(view.focusedControl, .workerButton)
        XCTAssertEqual(view.workerManager.state, .running)
        XCTAssertTrue(view.richLog.entries.map(\.message).contains("Worker started."))
        view.workerManager.cancel()
    }

    func testWorkerManagerPublishesProgressAndCompletion() async throws {
        let manager = WorkerManager()

        manager.startDemoTask(steps: 2, interval: .milliseconds(1))
        try await Task.sleep(for: .milliseconds(20))
        let events = manager.drainEvents()

        XCTAssertTrue(events.contains(WorkerEvent(state: .running, progress: 0, message: "Worker started.")))
        XCTAssertTrue(events.contains(where: { $0.state == .running && $0.progress > 0 }))
        XCTAssertTrue(events.contains(WorkerEvent(state: .completed, progress: 1, message: "Worker completed.")))
    }

    func testTSSDemoRendersRightSideStylesheetPanel() {
        var view = TSSDemoViewContainer(baseDemo: TSSDemoViewContainer.frozenBaseDemo())

        let canvas = view.render(size: TerminalSize(columns: 180, rows: 32))

        XCTAssertEqual(canvas[179, 0].style.background, .blue)
        XCTAssertEqual(canvas[129, 2].character, "T")
        XCTAssertEqual(canvas[130, 4].character, "0")
        XCTAssertEqual(canvas[130, 7].character, "1")
        XCTAssertEqual(canvas[134, 7].character, "/")
        XCTAssertEqual(canvas[126, 1].style.background, .blue)
    }

    func testTSSDemoDividerDragResizesStylesheetPanel() {
        var view = TSSDemoViewContainer(baseDemo: TSSDemoViewContainer.frozenBaseDemo())
        let size = TerminalSize(columns: 180, rows: 32)

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 126, y: 10), pressed: true)), terminalSize: size), .none)
        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 118, y: 10), pressed: true)), terminalSize: size), .none)
        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .release, location: Point(x: 118, y: 10), pressed: false)), terminalSize: size), .none)

        let canvas = view.render(size: size)
        XCTAssertEqual(canvas[118, 1].style.background, .blue)
        XCTAssertEqual(canvas[121, 2].character, "T")
    }

    func testTSSDemoRoutesBaseDemoVerticalSplitDragUsingLeftPaneSize() {
        var view = TSSDemoViewContainer(baseDemo: TSSDemoViewContainer.frozenBaseDemo())
        let size = TerminalSize(columns: 180, rows: 32)

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 10, y: 24), pressed: true)), terminalSize: size), .none)
        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 10, y: 22), pressed: true)), terminalSize: size), .none)

        XCTAssertEqual(view.baseDemo.logSplitDividerOffset, 21)
        XCTAssertTrue(view.baseDemo.logSplitIsDragging)
    }

    func testHorizontalSplitViewComputesFramesAndDragsDivider() {
        var split = HorizontalSplitView(
            frame: Rect(x: 2, y: 1, width: 20, height: 8),
            dividerOffset: 8,
            minLeading: 4,
            minTrailing: 5
        )
        var canvas = Canvas(size: TerminalSize(columns: 30, rows: 12))

        split.render(in: &canvas)

        XCTAssertEqual(split.leadingFrame, Rect(x: 2, y: 1, width: 8, height: 8))
        XCTAssertEqual(split.dividerFrame, Rect(x: 10, y: 1, width: 1, height: 8))
        XCTAssertEqual(split.trailingFrame, Rect(x: 11, y: 1, width: 11, height: 8))
        XCTAssertEqual(canvas[10, 4].style.background, .blue)
        XCTAssertEqual(split.handle(.mouse(MouseEvent(button: .left, location: Point(x: 10, y: 4), pressed: true))), .focused)
        XCTAssertEqual(split.handle(.mouse(MouseEvent(button: .left, location: Point(x: 15, y: 4), pressed: true))), .resized(13))
        XCTAssertEqual(split.dividerFrame.x, 15)
    }

    func testVerticalSplitViewComputesFramesAndDragsDivider() {
        var split = VerticalSplitView(
            frame: Rect(x: 2, y: 1, width: 20, height: 12),
            dividerOffset: 5,
            minTop: 3,
            minBottom: 2
        )
        var canvas = Canvas(size: TerminalSize(columns: 30, rows: 16))

        split.render(in: &canvas)

        XCTAssertEqual(split.topFrame, Rect(x: 2, y: 1, width: 20, height: 5))
        XCTAssertEqual(split.dividerFrame, Rect(x: 2, y: 6, width: 20, height: 1))
        XCTAssertEqual(split.bottomFrame, Rect(x: 2, y: 7, width: 20, height: 6))
        XCTAssertEqual(canvas[10, 6].style.background, .blue)
        XCTAssertEqual(split.handle(.mouse(MouseEvent(button: .left, location: Point(x: 10, y: 6), pressed: true))), .focused)
        XCTAssertEqual(split.handle(.mouse(MouseEvent(button: .left, location: Point(x: 10, y: 9), pressed: true))), .resized(8))
        XCTAssertEqual(split.dividerFrame.y, 9)
    }

    func testVerticalSplitViewCanDisableMinimumPaneClamping() {
        let clamped = VerticalSplitView(
            frame: Rect(x: 0, y: 0, width: 20, height: 10),
            dividerOffset: 20,
            minTop: 3,
            minBottom: 4,
            isClamped: true
        )
        let unclamped = VerticalSplitView(
            frame: Rect(x: 0, y: 0, width: 20, height: 10),
            dividerOffset: 20,
            minTop: 3,
            minBottom: 4,
            isClamped: false
        )

        XCTAssertEqual(clamped.dividerFrame.y, 5)
        XCTAssertEqual(unclamped.dividerFrame.y, 9)
    }

    func testHorizontalSplitViewCanDisableMinimumPaneClamping() {
        let clamped = HorizontalSplitView(
            frame: Rect(x: 0, y: 0, width: 20, height: 10),
            dividerOffset: 20,
            minLeading: 4,
            minTrailing: 6,
            isClamped: true
        )
        let unclamped = HorizontalSplitView(
            frame: Rect(x: 0, y: 0, width: 20, height: 10),
            dividerOffset: 20,
            minLeading: 4,
            minTrailing: 6,
            isClamped: false
        )

        XCTAssertEqual(clamped.dividerFrame.x, 13)
        XCTAssertEqual(unclamped.dividerFrame.x, 19)
    }

    func testTSSDemoSelectorSwitchesDisplayedStylesheetText() {
        var view = TSSDemoViewContainer(baseDemo: TSSDemoViewContainer.frozenBaseDemo())
        let size = TerminalSize(columns: 180, rows: 32)

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 130, y: 4), pressed: true)), terminalSize: size), .none)
        XCTAssertTrue(view.styleSelector.isOpen)
        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 130, y: 6), pressed: true)), terminalSize: size), .none)

        XCTAssertEqual(view.selectedStylesheetIndex, 1)
        XCTAssertFalse(view.styleSelector.isOpen)
        XCTAssertTrue(view.sourceView.source.contains("/* Current target set for the active implementation step."))
        XCTAssertTrue(view.baseDemo.richLog.entries.map(\.message).contains("TCSS demo selected: 01-current-target.tcss."))
    }

    func testTSSDemoAppliesSelectedTCSSMenuBarAndScreenStyles() {
        var view = TSSDemoViewContainer(baseDemo: TSSDemoViewContainer.frozenBaseDemo())
        let size = TerminalSize(columns: 180, rows: 32)
        let index = view.stylesheets.firstIndex { $0.fileName == "06-that70sShow.tcss" }!

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 130, y: 4), pressed: true)), terminalSize: size), .none)
        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 130, y: 5 + index), pressed: true)), terminalSize: size), .none)

        XCTAssertEqual(view.selectedStylesheetIndex, index)
        XCTAssertEqual(view.baseDemo.backgroundStyle.background, .rgb(255, 112, 67))
        XCTAssertEqual(view.baseDemo.backgroundStyle.foreground, .rgb(0, 255, 213))
        XCTAssertEqual(view.baseDemo.menuBar.barStyle.background, .rgb(156, 39, 176))
        XCTAssertEqual(view.baseDemo.menuBar.barStyle.foreground, .rgb(255, 235, 59))
        XCTAssertTrue(view.baseDemo.menuBar.barStyle.bold)
        XCTAssertEqual(view.baseDemo.menuBar.menuStyle.background, .rgb(255, 64, 129))
        XCTAssertEqual(view.baseDemo.menuBar.menuStyle.foreground, .rgb(0, 255, 213))
        XCTAssertEqual(view.baseDemo.menuBar.selectedItemStyle.background, .rgb(0, 188, 212))
        XCTAssertEqual(view.baseDemo.menuBar.selectedItemStyle.foreground, .rgb(74, 20, 140))

        view.baseDemo.menuBar.openedMenuIndex = 0
        let canvas = view.render(size: size)
        XCTAssertEqual(canvas[20, 0].style.background, .rgb(156, 39, 176))
        XCTAssertEqual(canvas[20, 0].style.foreground, .rgb(255, 235, 59))
        XCTAssertEqual(canvas[20, 2].style.background, .rgb(255, 112, 67))
        XCTAssertEqual(canvas[8, 1].style.background, .rgb(0, 188, 212))
        XCTAssertEqual(canvas[8, 1].style.foreground, .rgb(74, 20, 140))
    }

    func testTSSDemoSwitchingBackToBaselineResetsTCSSAppliedStyles() {
        var view = TSSDemoViewContainer(baseDemo: TSSDemoViewContainer.frozenBaseDemo())
        let size = TerminalSize(columns: 180, rows: 32)
        let loudIndex = view.stylesheets.firstIndex { $0.fileName == "06-that70sShow.tcss" }!

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 130, y: 4), pressed: true)), terminalSize: size), .none)
        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 130, y: 5 + loudIndex), pressed: true)), terminalSize: size), .none)
        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 130, y: 4), pressed: true)), terminalSize: size), .none)
        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 130, y: 5), pressed: true)), terminalSize: size), .none)

        XCTAssertEqual(view.selectedStylesheetIndex, 0)
        XCTAssertEqual(view.baseDemo.backgroundStyle.background, .brightBlack)
        XCTAssertEqual(view.baseDemo.menuBar.barStyle.background, .blue)
        XCTAssertEqual(view.baseDemo.menuBar.menuStyle.background, .brightBlack)
        XCTAssertEqual(view.baseDemo.menuBar.selectedItemStyle.background, .blue)
    }

    func testTSSDemoAppliesButtonStylesAndSizing() {
        var view = TSSDemoViewContainer(baseDemo: TSSDemoViewContainer.frozenBaseDemo())
        let size = TerminalSize(columns: 180, rows: 32)
        let currentTargetIndex = view.stylesheets.firstIndex { $0.fileName == "01-current-target.tcss" }!

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 130, y: 4), pressed: true)), terminalSize: size), .none)
        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 130, y: 5 + currentTargetIndex), pressed: true)), terminalSize: size), .none)

        XCTAssertEqual(view.baseDemo.button.frame.width, 18)
        XCTAssertEqual(view.baseDemo.button.frame.height, 1)
        XCTAssertEqual(view.baseDemo.demoButtons[0].frame.width, 18)
        XCTAssertEqual(view.baseDemo.demoButtons[0].frame.height, 1)
        XCTAssertEqual(view.baseDemo.demoButtons[0].style.background, .brightWhite)
        XCTAssertEqual(view.baseDemo.demoButtons[1].focusedStyle.background, .blue)
        XCTAssertTrue(view.baseDemo.demoButtons[1].focusedStyle.bold)

        let canvas = view.render(size: size)
        XCTAssertEqual(canvas[2, 11].style.background, .brightWhite)
        XCTAssertEqual(canvas[18, 11].style.background, .blue)
        XCTAssertEqual(canvas[34, 11].style.background, .brightWhite)
    }

    func testTSSDemoAppliesLargeButtonSizingAndCanReset() {
        var view = TSSDemoViewContainer(baseDemo: TSSDemoViewContainer.frozenBaseDemo())
        let size = TerminalSize(columns: 200, rows: 36)
        let bigIndex = view.stylesheets.firstIndex { $0.fileName == "04-big.tcss" }!

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 150, y: 4), pressed: true)), terminalSize: size), .none)
        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 150, y: 5 + bigIndex), pressed: true)), terminalSize: size), .none)
        XCTAssertEqual(view.baseDemo.demoButtons[0].frame.width, 120)
        XCTAssertEqual(view.baseDemo.demoButtons[0].frame.height, 8)

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 150, y: 4), pressed: true)), terminalSize: size), .none)
        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 150, y: 5), pressed: true)), terminalSize: size), .none)
        XCTAssertEqual(view.baseDemo.demoButtons[0].frame.width, 14)
        XCTAssertEqual(view.baseDemo.demoButtons[0].frame.height, 1)
    }

    func testTSSDemoAppliesTCSSAcrossRemainingControls() {
        let stylesheet = TSSDemoStylesheet(
            fileName: "all-controls.tcss",
            source: """
            Label { background: red; color: white; }
            Label.centered { background: cyan; color: black; text-align: right; }
            Vertical { background: green; color: black; }
            Horizontal { background: yellow; color: black; }
            TextInput { background: ansi(52); color: bright-white; width: 30; }
            TextInput:focus { background: blue; color: bright-white; }
            Placeholder { color: bright-black; }
            Cursor { background: bright-white; color: black; }
            Checkbox:checked { background: green; color: black; }
            Switch:on { background: green; color: black; }
            Select { background: red; color: white; }
            Select:open { background: bright-white; color: black; }
            Option:selected { background: blue; color: bright-white; }
            ScrollView { background: black; color: cyan; width: 28; height: 6; }
            ScrollContent { background: black; color: yellow; }
            ScrollBar { background: bright-black; color: white; }
            ScrollBarThumb { background: magenta; color: white; }
            Modal { background: ansi(53); color: bright-white; width: 40; height: 9; }
            ModalTitle { background: magenta; color: yellow; }
            ModalButton:focus { background: cyan; color: black; }
            ProgressBar { background: black; color: white; width: 24; }
            ProgressBar:complete { background: green; color: black; }
            ProgressBarText { color: yellow; }
            RichLog { background: black; color: cyan; }
            RichLogTitle { background: cyan; color: black; }
            DataTable { background: ansi(17); color: bright-white; }
            Header { background: cyan; color: black; }
            Row:alternate { background: ansi(18); color: bright-white; }
            Row:selected { background: blue; color: bright-white; }
            Tree { background: black; color: bright-white; width: 32; height: 8; }
            Tree:selected { background: yellow; color: black; }
            TreeBranch { color: cyan; }
            CommandPalette { background: black; color: bright-white; width: 48; }
            CommandPaletteTitle { background: magenta; color: yellow; }
            CommandPaletteInput { background: bright-black; color: cyan; }
            CommandPaletteItem:selected { background: green; color: black; }
            WorkerProgress { background: black; color: white; }
            WorkerProgress:complete { background: cyan; color: black; }
            WorkerProgressText { color: yellow; }
            """
        )
        let view = TSSDemoViewContainer(baseDemo: TSSDemoViewContainer.frozenBaseDemo(), stylesheets: [stylesheet])

        XCTAssertEqual(view.baseDemo.demoLabels[0].style.background, .red)
        XCTAssertEqual(view.baseDemo.demoLabels[1].style.background, .cyan)
        XCTAssertEqual(view.baseDemo.demoLabels[1].alignment, .right)
        XCTAssertEqual(view.baseDemo.verticalFillStyle.background, .green)
        XCTAssertEqual(view.baseDemo.horizontalFillStyle.background, .yellow)
        XCTAssertEqual(view.baseDemo.textInput.frame.width, 30)
        XCTAssertEqual(view.baseDemo.textInput.style.background, .ansi(52))
        XCTAssertEqual(view.baseDemo.textInput.focusedStyle.background, .blue)
        XCTAssertEqual(view.baseDemo.checkbox.checkedStyle.background, .green)
        XCTAssertEqual(view.baseDemo.toggleSwitch.onStyle.background, .green)
        XCTAssertEqual(view.baseDemo.select.style.background, .red)
        XCTAssertEqual(view.baseDemo.select.openStyle.background, .brightWhite)
        XCTAssertEqual(view.baseDemo.select.highlightedStyle.background, .blue)
        XCTAssertEqual(view.baseDemo.scrollView.frame.width, 28)
        XCTAssertEqual(view.baseDemo.scrollView.thumbStyle.background, .magenta)
        XCTAssertEqual(view.baseDemo.modal.frame.width, 40)
        XCTAssertEqual(view.baseDemo.modal.titleStyle.background, .magenta)
        XCTAssertEqual(view.baseDemo.progressBar.frame.width, 24)
        XCTAssertEqual(view.baseDemo.progressBar.completedStyle.background, .green)
        XCTAssertEqual(view.baseDemo.richLog.titleStyle.background, .cyan)
        XCTAssertEqual(view.baseDemo.dataTable.headerStyle.background, .cyan)
        XCTAssertEqual(view.baseDemo.dataTable.selectedRowStyle.background, .blue)
        XCTAssertEqual(view.baseDemo.tree.frame.width, 32)
        XCTAssertEqual(view.baseDemo.tree.selectedStyle.background, .yellow)
        XCTAssertEqual(view.baseDemo.commandPalette.frame.width, 48)
        XCTAssertEqual(view.baseDemo.commandPalette.titleStyle.background, .magenta)
        XCTAssertEqual(view.baseDemo.workerProgressCompletedStyle.background, .cyan)
    }

    func testSyntaxHighlightedScrollViewUsesRichSwiftSyntaxColors() {
        var canvas = Canvas(size: TerminalSize(columns: 40, rows: 4))
        let preview = SyntaxHighlightedScrollView(
            frame: Rect(x: 0, y: 0, width: 40, height: 4),
            source: "Button {\n    background: blue;\n}",
            lineNumbers: false
        )

        preview.render(in: &canvas)

        XCTAssertEqual(canvas[4, 1].character, "b")
        XCTAssertEqual(canvas[4, 1].style.foreground, .magenta)
        XCTAssertTrue(canvas[4, 1].style.bold)
    }

    func testTSSDemoIncludesEdgeCaseStylesheets() {
        let stylesheets = TSSDemoViewContainer.defaultStylesheets()

        XCTAssertTrue(stylesheets.map(\.fileName).contains("04-big.tcss"))
        XCTAssertTrue(stylesheets.map(\.fileName).contains("05-small.tcss"))
        XCTAssertTrue(stylesheets.map(\.fileName).contains("06-that70sShow.tcss"))
        XCTAssertTrue(stylesheets.first(where: { $0.fileName == "06-that70sShow.tcss" })?.source.contains("Never do this") == true)
    }

    func testTCSSParserParsesCommentsSelectorsPseudoStatesAndDeclarations() {
        let source = """
        /* first target */
        Button:focus,
        Label.centered {
            background: blue;
            color: bright-white;
            text-style: bold;
        }
        """

        let stylesheet = TCSSParser().parse(source)

        XCTAssertTrue(stylesheet.diagnostics.isEmpty)
        XCTAssertEqual(stylesheet.rules.count, 1)
        XCTAssertEqual(stylesheet.rules[0].selectors.count, 2)
        XCTAssertEqual(stylesheet.rules[0].selectors[0].segments[0].typeName, "Button")
        XCTAssertEqual(stylesheet.rules[0].selectors[0].segments[0].pseudoStates, ["focus"])
        XCTAssertEqual(stylesheet.rules[0].selectors[1].segments[0].typeName, "Label")
        XCTAssertEqual(stylesheet.rules[0].selectors[1].segments[0].classNames, ["centered"])
        XCTAssertEqual(stylesheet.rules[0].declarations, [
            TCSSDeclaration(property: "background", value: "blue", line: 4),
            TCSSDeclaration(property: "color", value: "bright-white", line: 5),
            TCSSDeclaration(property: "text-style", value: "bold", line: 6)
        ])
    }

    func testTCSSParserParsesChildAndDescendantCombinators() {
        let source = """
        DataTable > Header {
            background: cyan;
        }

        ScrollView ScrollBarThumb {
            background: blue;
        }
        """

        let stylesheet = TCSSParser().parse(source)

        XCTAssertTrue(stylesheet.diagnostics.isEmpty)
        XCTAssertEqual(stylesheet.rules[0].selectors[0].segments.map(\.typeName), ["DataTable", "Header"])
        XCTAssertEqual(stylesheet.rules[0].selectors[0].segments[1].combinator, .child)
        XCTAssertEqual(stylesheet.rules[1].selectors[0].segments.map(\.typeName), ["ScrollView", "ScrollBarThumb"])
        XCTAssertEqual(stylesheet.rules[1].selectors[0].segments[1].combinator, .descendant)
    }

    func testTCSSParserReportsDiagnosticsForMalformedBlocks() {
        let source = """
        Button {
            background blue;
            color:
        }

        }

        Label {
            color: cyan;
        """

        let stylesheet = TCSSParser().parse(source)
        let messages = stylesheet.diagnostics.map(\.message)

        XCTAssertTrue(messages.contains("Expected ':' in declaration 'background blue'."))
        XCTAssertTrue(messages.contains("Declaration 'color' is missing a value."))
        XCTAssertTrue(messages.contains("Unexpected '}' without a matching block."))
        XCTAssertTrue(messages.contains("Unclosed declaration block for selector 'Label'."))
        XCTAssertEqual(stylesheet.rules.count, 2)
    }

    func testTCSSStyleModelMapsTerminalAndLayoutDeclarations() {
        let source = """
        Button:focus {
            background: #336699;
            color: bright-white;
            text-style: bold inverse;
            width: 24;
            height: 1;
            padding: 1 2;
            text-align: center;
            divider-size: 1;
        }
        """

        let model = TCSSStyleModelBuilder().parse(source)

        XCTAssertTrue(model.diagnostics.isEmpty)
        XCTAssertEqual(model.rules.count, 1)
        let style = model.rules[0].style
        XCTAssertEqual(style.terminalStyle.background, .rgb(0x33, 0x66, 0x99))
        XCTAssertEqual(style.terminalStyle.foreground, .brightWhite)
        XCTAssertEqual(style.terminalStyle.bold, true)
        XCTAssertEqual(style.terminalStyle.inverse, true)
        XCTAssertEqual(style.layout.width, 24)
        XCTAssertEqual(style.layout.height, 1)
        XCTAssertEqual(style.layout.padding, TCSSBoxEdges(top: 1, right: 2, bottom: 1, left: 2))
        XCTAssertEqual(style.layout.textAlign, .center)
        XCTAssertEqual(style.layout.dividerWidth, 1)
        XCTAssertEqual(style.layout.dividerHeight, 1)
    }

    func testTCSSStylePatchAppliesOnlyDeclaredTerminalValues() {
        let source = """
        Label {
            color: ansi(10);
            bold: true;
        }
        """
        let base = TerminalStyle(foreground: .red, background: .black, bold: false, inverse: true)

        let model = TCSSStyleModelBuilder().parse(source)
        let applied = model.rules[0].style.terminalStyle.applied(to: base)

        XCTAssertEqual(applied.foreground, .ansi(10))
        XCTAssertEqual(applied.background, .black)
        XCTAssertEqual(applied.bold, true)
        XCTAssertEqual(applied.inverse, true)
    }

    func testTCSSStyleModelReportsUnsupportedValues() {
        let source = """
        Button {
            background: plaid;
            width: huge;
            padding: 1 2 3 4 5;
            text-align: sideways;
            unknown-thing: yep;
        }
        """

        let messages = TCSSStyleModelBuilder().parse(source).diagnostics.map(\.message)

        XCTAssertTrue(messages.contains("Unsupported color value 'plaid' for 'background'."))
        XCTAssertTrue(messages.contains("Expected non-negative integer value for 'width', got 'huge'."))
        XCTAssertTrue(messages.contains("Expected one to four non-negative integers for 'padding', got '1 2 3 4 5'."))
        XCTAssertTrue(messages.contains("Unsupported text-align value 'sideways'."))
        XCTAssertTrue(messages.contains("Unsupported TCSS property 'unknown-thing'."))
    }

    func testTCSSCascadeResolvesSpecificityAndSourceOrder() {
        let model = TCSSStyleModelBuilder().parse("""
        Button {
            background: red;
            color: white;
        }

        Button:focus {
            background: blue;
        }

        Button.primary {
            color: yellow;
        }

        Button.primary {
            color: cyan;
        }
        """)

        let style = TCSSCascade(model: model).style(
            for: TCSSStyleContext(typeName: "Button", classNames: ["primary"], pseudoStates: ["focus"])
        )

        XCTAssertEqual(style.terminalStyle.background, .blue)
        XCTAssertEqual(style.terminalStyle.foreground, .cyan)
    }

    func testMainViewLogsControlActions() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        _ = view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 47, y: 6), pressed: true)))
        _ = view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 69, y: 6), pressed: true)))
        _ = view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 85, y: 6), pressed: true)))
        _ = view.handle(.key(.down))
        _ = view.handle(.key(.enter))
        _ = view.handle(.mouse(MouseEvent(button: .scrollDown, location: Point(x: 75, y: 15), pressed: true)))
        _ = view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 58, y: 19), pressed: true)))
        _ = view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 75, y: 12), pressed: true)))

        let messages = view.richLog.entries.map(\.message)
        XCTAssertTrue(messages.contains("Checkbox changed: unchecked."))
        XCTAssertTrue(messages.contains("Switch changed: off."))
        XCTAssertTrue(messages.contains("Select picked: Beta."))
        XCTAssertTrue(messages.contains("Scroll view moved to offset 1."))
        XCTAssertTrue(messages.contains("Progress animation started: 0% to 100%."))
        XCTAssertTrue(messages.contains("Data table selected row 3: Log / Ready."))
    }

    func testMainViewCanToggleLogSplitClampingWithMouse() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertFalse(view.splitClampSwitch.isOn)
        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 117, y: 16), pressed: true))), .none)

        XCTAssertTrue(view.splitClampSwitch.isOn)
        XCTAssertEqual(view.focusedControl, .splitClampSwitch)
        XCTAssertTrue(view.richLog.entries.map(\.message).contains("Log split clamp changed: clamped."))
    }

    func testMainViewCanToggleLogSplitClampingWithKeyboard() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        for _ in 0..<12 { _ = view.handle(.key(.tab)) }
        XCTAssertEqual(view.focusedControl, .splitClampSwitch)
        XCTAssertEqual(view.handle(.key(.character(" "))), .none)

        XCTAssertTrue(view.splitClampSwitch.isOn)
        XCTAssertTrue(view.richLog.entries.map(\.message).contains("Log split clamp changed: clamped."))
    }

    func testMainViewLogSplitUnclampedAllowsDividerToUseMoreSpaceOnShortScreens() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        let unclamped = view.render(size: TerminalSize(columns: 80, rows: 12))
        view.splitClampSwitch.isOn = true
        let clamped = view.render(size: TerminalSize(columns: 80, rows: 12))

        XCTAssertEqual(clamped[10, 10].style.background, .blue)
        XCTAssertEqual(unclamped[10, 11].style.background, .blue)
    }

    func testMainViewCanDragVerticalLogSplitWithoutLoggingDebugNoise() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )
        let size = TerminalSize(columns: 80, rows: 24)

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 10, y: 22), pressed: true)), terminalSize: size), .none)
        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 10, y: 18), pressed: true)), terminalSize: size), .none)

        let messages = view.richLog.entries.map(\.message)
        XCTAssertEqual(view.logSplitDividerOffset, 17)
        XCTAssertTrue(view.logSplitIsDragging)
        XCTAssertFalse(messages.contains { $0.hasPrefix("Log split drag:") })
    }

    func testMainViewLogsModalOptionSelection() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        _ = view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 38, y: 18), pressed: true)))
        _ = view.handle(.key(.right))
        _ = view.handle(.key(.enter))

        XCTAssertTrue(view.richLog.entries.map(\.message).contains("Modal picked option: Cancel."))
    }

    func testMainViewProgressAnimationAdvancesOverFiveSeconds() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )
        let start = Date(timeIntervalSinceReferenceDate: 100)

        view.startProgressAnimation(now: start)
        view.updateProgressAnimation(now: start.addingTimeInterval(2.5))
        XCTAssertEqual(view.progressBar.value ?? -1, 0.5, accuracy: 0.001)
        XCTAssertNotNil(view.progressAnimationStartedAt)

        view.updateProgressAnimation(now: start.addingTimeInterval(5))
        XCTAssertEqual(view.progressBar.value ?? -1, 1, accuracy: 0.001)
        XCTAssertNil(view.progressAnimationStartedAt)
    }

    func testMainViewRoutesEventsToPresentedModal() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )
        view.modal.present()

        XCTAssertEqual(view.handle(.key(.escape)), .none)
        XCTAssertFalse(view.modal.isPresented)
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

    func testDemoRendersHorizontalContainerExample() {
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

        XCTAssertEqual(canvas[36, 14].character, "H")
        XCTAssertEqual(canvas[52, 14].character, "O")
        XCTAssertEqual(canvas[62, 14].character, "T")
        XCTAssertEqual(canvas[36, 14].style.background, .black)
        XCTAssertEqual(canvas[62, 14].style.background, .blue)
    }

    func testDemoRendersTextInputExample() {
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

        XCTAssertEqual(canvas[19, 6].character, "S")
        XCTAssertEqual(canvas[19, 6].style.background, .black)
        XCTAssertEqual(canvas[18, 6].style.background, .black)
    }

    func testDemoRendersCheckboxExample() {
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

        XCTAssertEqual(canvas[46, 6].character, "[")
        XCTAssertEqual(canvas[47, 6].character, "x")
        XCTAssertEqual(canvas[50, 6].character, "E")
    }

    func testDemoRendersSwitchExample() {
        let view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        let canvas = view.render(size: TerminalSize(columns: 100, rows: 24))

        XCTAssertEqual(canvas[68, 6].character, "<")
        XCTAssertEqual(canvas[69, 6].character, "O")
        XCTAssertEqual(canvas[70, 6].character, "N")
        XCTAssertEqual(canvas[73, 6].character, "P")
        XCTAssertEqual(canvas[68, 6].style.background, .green)
    }

    func testDemoRendersSelectExample() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )
        view.splitClampSwitch.isOn = true

        let canvas = view.render(size: TerminalSize(columns: 110, rows: 24))

        XCTAssertEqual(canvas[85, 6].character, "A")
        XCTAssertEqual(canvas[91, 6].character, "v")
    }

    func testDemoRendersScrollViewExample() {
        let view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        let canvas = view.render(size: TerminalSize(columns: 110, rows: 24))

        XCTAssertEqual(canvas[74, 14].character, "S")
        XCTAssertEqual(canvas[85, 14].character, "1")
        XCTAssertEqual(canvas[97, 14].style.background, .blue)
    }

    func testDemoRendersModalButtonExample() {
        let view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        let canvas = view.render(size: TerminalSize(columns: 110, rows: 24))

        XCTAssertEqual(canvas[38, 18].character, "S")
        XCTAssertEqual(canvas[43, 18].character, "m")
    }

    func testDemoRendersProgressBarExample() {
        let view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        let canvas = view.render(size: TerminalSize(columns: 110, rows: 24))

        XCTAssertEqual(canvas[58, 18].character, "L")
        XCTAssertEqual(canvas[63, 18].character, "6")
        XCTAssertEqual(canvas[65, 18].character, "%")
    }

    func testDemoRendersProgressAnimationButtonExample() {
        let view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        let canvas = view.render(size: TerminalSize(columns: 110, rows: 24))

        XCTAssertEqual(canvas[58, 19].character, "A")
        XCTAssertEqual(canvas[64, 19].character, "e")
    }

    func testDemoRendersRichLogExample() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )
        view.splitClampSwitch.isOn = true

        let canvas = view.render(size: TerminalSize(columns: 110, rows: 24))

        XCTAssertEqual(canvas[10, 22].style.background, .blue)
        XCTAssertEqual(canvas[3, 23].character, "R")
    }

    func testDemoRendersDataTableExample() {
        let view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        let canvas = view.render(size: TerminalSize(columns: 110, rows: 24))

        XCTAssertEqual(canvas[75, 8].character, "F")
        XCTAssertEqual(canvas[88, 8].character, "S")
        XCTAssertEqual(canvas[75, 9].character, "M")
        XCTAssertEqual(canvas[75, 12].character, "L")
    }

    func testDemoRendersTreeExample() {
        let view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        let canvas = view.render(size: TerminalSize(columns: 140, rows: 24))

        XCTAssertEqual(canvas[100, 8].character, "v")
        XCTAssertEqual(canvas[102, 8].character, "S")
        XCTAssertEqual(canvas[102, 9].character, "v")
        XCTAssertEqual(canvas[104, 9].character, "C")
    }

    func testDemoRendersCommandPaletteAndWorkerExamples() {
        let view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        let canvas = view.render(size: TerminalSize(columns: 140, rows: 24))

        XCTAssertEqual(canvas[103, 16].character, "C")
        XCTAssertEqual(canvas[102, 18].character, "R")
        XCTAssertEqual(canvas[110, 20].character, "W")
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
