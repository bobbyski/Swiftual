# Clipboard Cut Copy And Paste Support Issue

## Status

Open. This is likely a framework-wide input and terminal-mode design issue, not only a `TextInput` issue.

## Summary

Cut, copy, and paste do not currently work in the demo application. Manual testing showed this while interacting with the terminal UI and then specifically while trying the `TextInput` control.

This needs a deliberate framework decision because terminal clipboard behavior can involve several different layers:

- Native terminal UI shortcuts, such as Command-C and Command-V on macOS terminal applications.
- Control-key input delivered to the program, such as Control-C.
- Raw pasted bytes delivered as normal text.
- Bracketed paste sequences, when enabled by the application.
- Future explicit clipboard actions exposed by controls, command palettes, or menus.

The surprising part is that the terminal itself did not appear to provide the expected fallback behavior during the running application. That may be a side effect of raw mode, alternate-screen mode, mouse reporting, or how the app consumes input.

## Expected Behavior

- Users should be able to paste text into focused editable controls.
- Copy and cut should have a clear supported path for selectable/editable text.
- Terminal-native copy/paste should not be accidentally broken by framework modes unless there is a documented reason.
- The test suite should cover paste handling explicitly so future controls inherit the same behavior.

## Actual Behavior

- Copy/cut/paste does not work from the running demo.
- The current input model has no paste event and no clipboard command abstraction.
- Pasted data, if delivered by the terminal, is currently indistinguishable from ordinary typed characters unless the terminal sends bracketed paste markers.

## Current Assumption

This should be treated as a framework feature gap. A fix probably belongs in the terminal backend and input parser first, then controls such as `TextInput` can opt into paste, cut, copy, and selection behavior.

Controls likely affected:

- `TextInput`
- Future multiline text input/editors
- Future selectable labels/logs/tables
- Command palette text entry
- Any future control with selection state

Controls likely unaffected except for global shortcuts:

- `Button`
- `Checkbox`
- `Switch`
- `ProgressBar`
- Layout containers

## Suspect Area 1: Raw Terminal Mode

File: `Code/Swiftual/Sources/Swiftual/Terminal.swift`

Function: `FileDescriptorTerminalDevice.enableRawMode()`

Why suspicious:

- Raw mode disables several terminal line-discipline features.
- `ISIG` is disabled, so Control-C is read by the app instead of being handled by the terminal driver.
- `ICANON`, `ECHO`, and `IEXTEN` are disabled, which is expected for a TUI but changes how input is delivered.
- This may affect how terminal-native editing and clipboard shortcuts behave while the app is active.

Current code:

```swift
    public func enableRawMode() throws {
        var current = termios()
        guard tcgetattr(input, &current) == 0 else {
            throw TerminalError.rawModeFailed(errno)
        }
        originalTermios = current

        current.c_lflag &= ~(UInt(ECHO | ICANON | IEXTEN | ISIG))
        current.c_iflag &= ~(UInt(IXON | ICRNL | BRKINT | INPCK | ISTRIP))
        current.c_oflag &= ~(UInt(OPOST))
        current.c_cflag |= UInt(CS8)
        current.c_cc.16 = 0
        current.c_cc.17 = 1

        guard tcsetattr(input, TCSAFLUSH, &current) == 0 else {
            throw TerminalError.rawModeFailed(errno)
        }
    }
```

## Suspect Area 2: Application And Mouse Modes

File: `Code/Swiftual/Sources/Swiftual/Terminal.swift`

Function: `ANSITerminalBackend.enterApplicationMode(device:)`

Why suspicious:

- The app enters the alternate screen.
- It enables mouse reporting modes.
- It does not currently enable bracketed paste mode.
- Mouse reporting can change selection behavior in many terminals because mouse drags are delivered to the app instead of the terminal selection layer.

Current code:

```swift
    public func enterApplicationMode(device: TerminalDevice) throws {
        try device.writeOutput("\u{001B}[?1049h\u{001B}[?25l\u{001B}[?1000h\u{001B}[?1002h\u{001B}[?1006h\u{001B}[2J\u{001B}[H")
    }

    public func exitApplicationMode(device: TerminalDevice) throws {
        try device.writeOutput("\u{001B}[?1006l\u{001B}[?1002l\u{001B}[?1000l\u{001B}[?25h\u{001B}[0m\u{001B}[?1049l")
    }
```

Possible future change:

- Consider enabling bracketed paste with `ESC[?2004h` on entry and disabling it with `ESC[?2004l` on exit.
- Add a corresponding input event such as `InputEvent.paste(String)`.

## Suspect Area 3: Input Parser Has No Paste Model

File: `Code/Swiftual/Sources/Swiftual/Input.swift`

Function: `InputParser.parse(_:)`

Why suspicious:

- There is no recognition of bracketed paste markers.
- Multi-character text is split into individual character events.
- This is good enough for typing, but it loses paste boundaries and prevents controls from distinguishing typed text from pasted text.

Current code:

```swift
    public func parse(_ bytes: [UInt8]) -> [InputEvent] {
        guard !bytes.isEmpty else { return [] }
        let text = String(decoding: bytes, as: UTF8.self)

        if text.count > 1, !text.hasPrefix("\u{1B}[<") {
            var events: [InputEvent] = []
            var index = text.startIndex

            while index < text.endIndex {
                let remaining = text[index...]
                if let arrow = parseArrowPrefix(remaining) {
                    events.append(.key(arrow.key))
                    index = text.index(index, offsetBy: arrow.length)
                } else {
                    let character = text[index]
                    events.append(contentsOf: parse(Array(String(character).utf8)))
                    index = text.index(after: index)
                }
            }

            return events
        }
```

## Suspect Area 4: TextInput Only Handles Single Characters

File: `Code/Swiftual/Sources/Swiftual/TextInput.swift`

Function: `handle(_:)`

Why suspicious:

- `TextInput` inserts single `.character` events.
- It has no paste command, no selection state, and no cut/copy command surface.
- It cannot currently support text-range replacement or clipboard operations cleanly.

Current code:

```swift
    public mutating func handle(_ event: InputEvent) -> TextInputCommand {
        guard isEnabled else { return .none }

        switch event {
        case .key(.character(let character)):
            guard isFocused else { return .none }
            insert(character)
            return .changed(text)
        case .key(.backspace):
            guard isFocused, cursorIndex > 0 else { return .none }
            let index = text.index(text.startIndex, offsetBy: cursorIndex - 1)
            text.remove(at: index)
            cursorIndex -= 1
            return .changed(text)
```

## Proposed Fix Direction

1. Add explicit paste support to the terminal backend.
2. Add bracketed paste parsing to the input layer.
3. Consider a new event shape, such as `InputEvent.paste(String)`, instead of flattening paste into many key events.
4. Add `TextInput` paste insertion tests.
5. Add a demo/test-suite button or instruction path that makes paste behavior easy to validate.
6. Evaluate cut/copy separately because terminal apps usually cannot access the system clipboard directly without either terminal cooperation, OSC 52, platform APIs, or an explicit dependency/adapter.

## Test Plan

- Parser test: complete bracketed paste sequence becomes one paste event.
- Parser test: bracketed paste split across reads does not leak marker characters into text.
- TextInput test: paste inserts full string at cursor.
- TextInput test: paste replaces selected text after selection exists.
- Demo test: paste into the visible text input logs one clean change message.
- Regression test: Control-C still exits the demo if that remains the desired app shortcut.

## Open Questions

- Should Swiftual expose clipboard operations through terminal protocols, platform protocols, or both?
- Should OSC 52 clipboard integration be supported by the ANSI backend?
- Should Command-C/Command-V be considered terminal-owned and outside the app, or should the framework provide first-class copy/paste commands where terminals can report them?
- Should mouse reporting be temporarily disabled while selecting text, or should Swiftual implement its own text selection model?
