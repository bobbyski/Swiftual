# Terminal Backends

Swiftual routes all terminal IO through protocols so real terminals, virtual terminals, and future backends can be swapped without changing controls.

## Core Types

- `TerminalDevice`: reads input bytes, writes output strings, reports terminal size, enables raw mode, and restores terminal mode.
- `TerminalBackend`: enters/exits application mode, renders a `Canvas`, and decodes input bytes into `InputEvent` values.
- `TerminalDetector`: chooses a backend automatically or from a manual selection.
- `ANSITerminalBackend`: the current backend implementation for ANSI and VT100-style terminals.

## Backend Selection

Automatic selection:

```swift
let backend = TerminalDetector.detect(selection: .automatic)
```

Manual ANSI selection:

```swift
let backend = TerminalDetector.detect(selection: .manual(.ansi))
```

Manual VT100 selection:

```swift
let backend = TerminalDetector.detect(selection: .manual(.vt100))
```

The demo also accepts command-line flags:

```bash
cd Code/SwiftualDemo
swift run swiftual-demo --ansi
swift run swiftual-demo --vt100
```

## ANSI Behavior

The ANSI backend currently:

- Enters alternate screen mode.
- Hides the cursor.
- Enables basic mouse reporting.
- Clears the screen and moves the cursor home.
- Disables auto-wrap while rendering a full frame.
- Restores auto-wrap after rendering.
- Shows the cursor and exits alternate screen mode on shutdown.

## Test Checklist

- Manual ANSI selection returns an ANSI backend.
- Manual VT100 selection returns a VT100-marked backend using the ANSI implementation.
- Rendering writes through `TerminalDevice`, not directly to stdout.
- Rendering begins from cursor home.
- Rendering disables and restores auto-wrap.
- Rendering does not append a trailing newline that scrolls the frame.
