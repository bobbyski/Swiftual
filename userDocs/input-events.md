# Input Events

Swiftual decodes terminal bytes into typed input events before controls see them.

## Core Types

```swift
public enum InputEvent {
    case key(Key)
    case mouse(MouseEvent)
}
```

```swift
public enum Key {
    case character(Character)
    case enter
    case escape
    case tab
    case backspace
    case up
    case down
    case left
    case right
    case controlC
    case unknown(String)
}
```

## Keyboard Support

Current parser support:

- Printable single characters.
- Enter.
- Escape.
- Tab.
- Backspace.
- Arrow keys.
- Ctrl-C.
- Unknown escape sequences as `.unknown`.

## Mouse Support

Current parser support:

- ANSI SGR mouse events.
- Left, middle, right, release, scroll up, scroll down.
- Zero-based terminal coordinates.

## Test Checklist

- Arrow escape sequences decode to arrow keys.
- Enter decodes from carriage return or newline.
- Ctrl-C decodes to `.controlC`.
- SGR mouse click decodes to a zero-based `MouseEvent`.
- Unknown input is preserved enough for debugging.

