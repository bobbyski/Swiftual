# Canvas And Rendering

`Canvas` is Swiftual's virtual terminal buffer. Controls render into a canvas; a terminal backend turns that canvas into terminal output.

## Core Types

```swift
public struct Cell {
    public var character: Character
    public var style: TerminalStyle
}
```

```swift
public struct Canvas {
    public let size: TerminalSize
}
```

## Drawing

Fill a region:

```swift
canvas.fill(
    rect: Rect(x: 0, y: 0, width: 80, height: 1),
    style: TerminalStyle(foreground: .brightWhite, background: .blue)
)
```

Draw text:

```swift
canvas.drawText("File", at: Point(x: 1, y: 0), style: menuStyle)
```

## Rendering Rules

- Coordinates are zero-based.
- Out-of-bounds writes are ignored.
- Rendering should not write directly to stdout.
- Rendering must go through `TerminalBackend.render(_:device:)`.
- ANSI rendering disables auto-wrap during frame paint.
- ANSI rendering does not append a trailing newline after the final row.

## Test Checklist

- Filling a rectangle applies style to every cell in the region.
- Drawing text writes expected characters and styles.
- Out-of-bounds writes do not crash.
- ANSI rendering includes cursor home.
- ANSI rendering avoids trailing newline scroll.
- ANSI rendering disables and restores auto-wrap.

