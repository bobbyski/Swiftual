# Mouse Escape Codes Inserted Into TextInput Issue

## Status

Open. This is likely an input parser buffering issue with a `TextInput` safety follow-up.

## Summary

While the `TextInput` control was focused, using the mouse wheel caused terminal mouse control-code fragments to be inserted into the field as plain text.

The screenshot showed values like this appearing inside the field and the rich log:

```text
57M[<65;23;57M4;22;57...
```

That looks like fragments of SGR mouse reports, especially scroll-wheel reports where code `65` means scroll down. The parser currently understands complete SGR mouse sequences, but it is not stateful across reads and does not parse multiple adjacent SGR sequences from one input buffer. If the terminal read starts in the middle of a sequence, the parser can degrade the remaining bytes into character events.

## Screenshot Reference

Save the manual test screenshot at:

```text
issues/assets/mouse_escape_codes_text_input.png
```

![Mouse escape codes inserted into focused text input](assets/mouse_escape_codes_text_input.png)

The screenshot shows `swiftual-tcss-demo` with the text input focused and filled with mouse-control fragments. The rich log also repeats `Text input changed:` messages containing the same escape-code fragments.

## Expected Behavior

- Mouse wheel input over the app should become `.mouse(.scrollUp)` or `.mouse(.scrollDown)` events.
- Mouse escape sequences should never be inserted into focused text fields.
- Incomplete escape sequences should be buffered until complete or discarded as control data, not converted into printable user text.
- `TextInput` should ignore non-printable escape/control fragments even if the parser misclassifies one.

## Actual Behavior

- Mouse wheel input produced visible escape-code fragments in the focused text input.
- The text input emitted repeated change messages containing the escape fragments.
- This makes the text model dirty and can flood logs.

## Current Assumption

The primary bug is in the input layer:

- Reads can contain partial escape sequences.
- Reads can contain multiple mouse sequences.
- The parser is stateless and operates on each read independently.

There is also a secondary hardening issue in `TextInput`:

- A text field should reject control/escape characters as text input unless a control explicitly opts into raw input.

## Suspect Area 1: Input Reads Can Split Or Join Escape Sequences

File: `Code/Swiftual/Sources/Swiftual/Terminal.swift`

Function: `FileDescriptorTerminalDevice.readInput(maxBytes:)`

Why suspicious:

- The device reads up to `maxBytes`, then drains currently pending bytes.
- This does not guarantee a full terminal escape sequence has arrived.
- It also does not guarantee only one event is present in the returned bytes.
- Scroll-wheel events can arrive quickly as repeated SGR reports.

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

## Suspect Area 2: Parser Only Accepts One Complete SGR Mouse Sequence

File: `Code/Swiftual/Sources/Swiftual/Input.swift`

Functions: `parse(_:)` and `parseSGRMouse(_:)`

Why suspicious:

- `parseSGRMouse(_:)` expects the whole string to be exactly one mouse sequence.
- If two mouse sequences are read together, the parser can fail because the body no longer has exactly three `;`-separated parts.
- If a read starts after the leading escape byte, the initial multi-character branch can split the fragments into individual characters.
- Those individual characters can become `.key(.character(...))` events.

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

```swift
    private func parseSGRMouse(_ text: String) -> MouseEvent? {
        guard text.hasPrefix("\u{1B}[<"), let suffix = text.last, suffix == "M" || suffix == "m" else {
            return nil
        }

        let body = text.dropFirst(3).dropLast()
        let parts = body.split(separator: ";")
        guard parts.count == 3,
              let code = Int(parts[0]),
              let column = Int(parts[1]),
              let row = Int(parts[2])
        else {
            return nil
        }

        return MouseEvent(
            button: mouseButton(from: code),
            location: Point(x: max(0, column - 1), y: max(0, row - 1)),
            pressed: suffix == "M"
        )
    }
```

## Suspect Area 3: TextInput Inserts Any Character Event

File: `Code/Swiftual/Sources/Swiftual/TextInput.swift`

Function: `handle(_:)`

Why suspicious:

- The text field trusts `.key(.character)` events.
- If the parser emits pieces of an escape sequence as characters, `TextInput` inserts them.
- This control should probably reject escape/control characters even after the parser is improved.

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

1. Replace `InputParser.parse(_:)` with a small stateful decoder that keeps a pending byte buffer.
2. Parse a stream into zero or more complete `InputEvent` values.
3. Leave incomplete escape sequences in the pending buffer until more bytes arrive.
4. Recognize multiple adjacent SGR mouse reports in one read.
5. Add explicit handling for scroll-wheel mouse codes `64` and `65` in stream parsing.
6. Harden `TextInput` so it only inserts printable characters and ignores escape/control fragments.
7. Add a focused text-input regression test that feeds fragmented mouse-wheel bytes and confirms no text changes.

## Test Plan

- Parser test: one complete scroll-down SGR sequence becomes `.mouse(.scrollDown)`.
- Parser test: two adjacent SGR mouse sequences become two mouse events.
- Parser test: a mouse sequence split across two reads emits no text characters and eventually emits one mouse event.
- TextInput test: `.mouse(.scrollDown)` while focused does not change text.
- TextInput test: malformed escape fragments do not insert into text.
- Demo test: scrolling the mouse wheel over a focused text input logs mouse/scroll behavior if desired, but never changes the text field.

## Open Questions

- Should scroll-wheel events over focused text inputs be ignored, forwarded to parent scroll containers, or used for cursor/history behavior?
- Should the parser expose diagnostics for discarded malformed escape sequences?
- Should low-level terminal reads remain stateless while a higher-level `InputDecoder` owns buffering, or should buffering live inside each `TerminalBackend` implementation?
