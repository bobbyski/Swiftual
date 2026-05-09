# TextInput Horizontal Scrolling And Cursor Issue

## Status

Open. This issue should not block work on unrelated controls.

## Summary

The `TextInput` control correctly retains typed text beyond the visible field width, but live terminal cursor movement and horizontal scrolling are still visually wrong after the field overflows.

Observed behavior:

- Typing past the visible width stores the full text.
- Backspace can bring hidden text back into view, proving the model has retained the characters.
- Moving left/backward after overflow appears one character off.
- Moving right/forward also appears one character off.
- Example from manual testing: text was `Johnny five is alive`; the visible cursor highlighted `v` where the expected highlighted character was `i`.

Current unit tests pass for the model and rendering cases we simulated, so the live failure is probably an integration mismatch between terminal input, cursor-index semantics, and viewport rendering.

## Current Assumption

This is likely isolated to `TextInput` and possibly the terminal input read/parser path. It should not affect unrelated controls such as checkbox, switch, select, menu, button, labels, or layout containers.

Controls likely unaffected:

- `MenuBar`
- `Menu`
- `MenuItem`
- `Button`
- `Label`
- `Vertical`
- `Horizontal`

Areas possibly affected:

- Future text editing controls.
- Any future controls that depend on multi-byte escape parsing or insertion-point cursor semantics.

## Suspect Area 1: TextInput Event Handling

File: `Sources/Swiftual/TextInput.swift`

Function: `handle(_:)`

Why suspicious:

- `cursorIndex` is currently used as an insertion-point index.
- Rendering uses the same value as a display cursor index.
- For block cursors, insertion-point and highlighted-character semantics can differ by one.
- Left/right movement itself is simple, but the visual expectation may require a clearer model: insertion point, highlighted cell, and viewport offset should probably be separate values.

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
        case .key(.left):
            guard isFocused else { return .none }
            cursorIndex = max(0, cursorIndex - 1)
            return .cursorMoved(cursorIndex)
        case .key(.right):
            guard isFocused else { return .none }
            cursorIndex = min(text.count, cursorIndex + 1)
            return .cursorMoved(cursorIndex)
        case .key(.enter):
            guard isFocused else { return .none }
            return .submitted(text)
        case .mouse(let mouse):
            guard mouse.pressed, mouse.button == .left, frame.contains(mouse.location) else {
                return .none
            }
            isFocused = true
            cursorIndex = min(text.count, max(0, mouse.location.x - frame.x - 1))
            return .focused
        default:
            return .none
        }
    }
```

## Suspect Area 2: TextInput Render Cursor And Viewport

File: `Sources/Swiftual/TextInput.swift`

Function: `render(in:)`

Why suspicious:

- The renderer computes `startIndex`, draws visible text, then overwrites one cell with `cursorStyle`.
- This is where the cursor-highlighted character can become one-off if `cursorIndex` means insertion point but rendering treats it as current character.
- It also clamps the cursor to `contentWidth - 1`, which may hide whether the logical cursor is at the trailing blank cell or a real character.

Current code:

```swift
        let startIndex = visibleStartIndex(contentWidth: contentWidth)
        let displayText: String
        let displayStyle: TerminalStyle
        if text.isEmpty && !isFocused {
            displayText = String(placeholder.prefix(contentWidth))
            displayStyle = placeholderStyle
        } else {
            displayText = visibleText(startIndex: startIndex, width: contentWidth)
            displayStyle = currentStyle
        }

        canvas.drawText(displayText, at: Point(x: frame.x + 1, y: frame.y), style: displayStyle)

        if isFocused {
            let displayCursorIndex = cursorIndex
            let cursorOffset = min(max(0, displayCursorIndex - startIndex), contentWidth - 1)
            let cursorX = frame.x + 1 + cursorOffset
            let cursorCharacter = displayCursorIndex < text.count
                ? text[text.index(text.startIndex, offsetBy: displayCursorIndex)]
                : " "
            canvas[cursorX, frame.y] = Cell(cursorCharacter, style: cursorStyle)
        }
```

## Suspect Area 3: TextInput Viewport Calculation

File: `Sources/Swiftual/TextInput.swift`

Function: `visibleStartIndex(contentWidth:)`

Why suspicious:

- The logic tries to reserve a trailing blank cursor cell when the cursor is at the end.
- When moving left/right within long text, it may shift the viewport differently than expected.
- The `desiredCursor` expression may not match the desired visible block-cursor semantics.

Current code:

```swift
    private func visibleStartIndex(contentWidth: Int) -> Int {
        guard contentWidth > 0, isFocused else { return 0 }
        let desiredCursor = cursorIndex == text.count ? cursorIndex + 1 : cursorIndex
        if desiredCursor <= contentWidth {
            return 0
        }
        return min(max(0, text.count - contentWidth + 1), desiredCursor - contentWidth)
    }

    private func visibleText(startIndex: Int, width: Int) -> String {
        guard width > 0 else { return "" }
        let start = text.index(text.startIndex, offsetBy: min(startIndex, text.count))
        let suffix = text[start...]
        return String(suffix.prefix(width))
    }
```

## Suspect Area 4: Input Parser

File: `Sources/Swiftual/Input.swift`

Function: `parse(_:)`

Why suspicious:

- Real terminals can deliver multiple keypresses in one read or split escape sequences across reads.
- The parser was expanded to split repeated arrow sequences and handle several arrow variants.
- Tests pass for synthetic complete sequences, but live behavior may still differ if partial escape sequences are returned.

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

        if let mouse = parseSGRMouse(text) {
            return [.mouse(mouse)]
        }
```

## Suspect Area 5: Terminal Raw Read Coalescing

File: `Sources/Swiftual/Terminal.swift`

Function: `FileDescriptorTerminalDevice.readInput(maxBytes:)`

Why suspicious:

- Raw mode currently uses `VMIN = 1` and `VTIME = 0`, so `read` can return as soon as one byte is available.
- A later patch attempts to coalesce immediately pending bytes with `select`, but this may still fail depending on timing.
- A more robust fix may require a stateful input decoder that buffers incomplete escape sequences across reads.

Current code:

```swift
    public func readInput(maxBytes: Int = 64) throws -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: max(1, maxBytes))
        let count = Darwin.read(input, &buffer, buffer.count)
        if count < 0 {
            throw TerminalError.readFailed(errno)
        }

        var bytes = Array(buffer.prefix(count))
        while bytes.count < maxBytes, hasPendingInput() {
            var next: UInt8 = 0
            let nextCount = Darwin.read(input, &next, 1)
            if nextCount <= 0 {
                break
            }
            bytes.append(next)
        }
        return bytes
    }
```

## Suspect Area 6: Main View Event Routing

File: `Sources/Swiftual/MenuControls.swift`

Function: `MainViewContainer.handle(_:)`

Why suspicious:

- This is less likely than the `TextInput` code, but it is where key events are forwarded into `textInput`.
- It currently discards the returned `TextInputCommand`.
- It mutates `textInput.isFocused` before forwarding the event, which is expected.

Current code:

```swift
        switch focusedControl {
        case .menuBar:
            return menuBar.handle(event)
        case .button:
            button.isFocused = true
            switch button.handle(event) {
            case .activated("Quit"):
                return .quit
            case .activated:
                return .none
            case .none:
                if case .mouse = event {
                    focusedControl = .menuBar
                    return menuBar.handle(event)
                }
                return .none
            }
        case .textInput:
            textInput.isFocused = true
            _ = textInput.handle(event)
            return .none
        }
```

## Likely Fix Direction

Recommended next attempt:

1. Split `TextInput` state into clearer fields:
   - `cursorIndex`: insertion point, range `0...text.count`.
   - `viewportStartIndex`: first visible character, persisted instead of recomputed each render.
   - `cursorDisplayColumn`: computed from cursor and viewport.
2. Decide explicit block-cursor semantics:
   - Option A: block cursor highlights the character at insertion point.
   - Option B: block cursor highlights the character before insertion point after moving left.
   - Current expectation from manual testing seems closer to Option A, with trailing blank only at end.
3. Add live-debug instrumentation behind a flag:
   - Raw input bytes.
   - Parsed `InputEvent`.
   - `text`.
   - `cursorIndex`.
   - `viewportStartIndex`.
   - highlighted character.
4. Consider changing `InputParser` into a stateful type that can buffer incomplete escape sequences across reads.

## Current Test Coverage

The test suite currently includes passing tests for:

- Horizontal scrolling at end.
- Scrolling back when moving left.
- Cursor highlighting on `Johnny five is alive`.
- Left from end highlighting the last character.
- Repeated left/right arrow sequence parsing.
- Alternate and modified arrow sequences.

Because the live demo still fails, the missing test is likely an integration-style test that mirrors the real terminal read/render loop more closely, or instrumentation that captures the actual byte stream from the terminal.

