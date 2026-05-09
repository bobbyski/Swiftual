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
