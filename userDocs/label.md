# Label And Static Text

`Label` renders non-interactive text into a fixed terminal-cell frame.

## Creation

```swift
let label = Label(
    "Swiftual demo",
    frame: Rect(x: 2, y: 2, width: 40, height: 1)
)
```

Styled label:

```swift
let label = Label(
    "Status: ready",
    frame: Rect(x: 0, y: 0, width: 20, height: 1),
    style: TerminalStyle(foreground: .yellow, background: .blue)
)
```

## Options

- `text`: visible text.
- `frame`: terminal-cell rectangle where the label renders.
- `style`: foreground, background, bold, and inverse style.
- `alignment`: `.left`, `.center`, or `.right`.

## Rendering Behavior

- Labels fill their frame with the configured style.
- Text renders on the first row of the frame.
- Text is clipped to the frame width.
- Labels do not receive keyboard or mouse input.
- Current implementation is one-line. Multi-line wrapping can be added later as a separate text/static feature.

## Alignment

Left aligned:

```swift
Label("Name", frame: rect, alignment: .left)
```

Centered:

```swift
Label("Name", frame: rect, alignment: .center)
```

Right aligned:

```swift
Label("Name", frame: rect, alignment: .right)
```

## Demo Coverage

The demo renders three showcase labels:

- Left-aligned white-on-grey label.
- Centered bold black-on-cyan label.
- Right-aligned yellow-on-blue label.

These examples are intentionally visible at the same time so alignment and style differences can be checked manually and through canvas tests.

## Test Checklist

- Label renders text at the frame origin when left aligned.
- Label applies foreground and background style.
- Label clips text to frame width.
- Center alignment places text in the horizontal center.
- Right alignment places text against the right edge.
- Empty or zero-size frames do not crash.
- Demo renders left, centered, and right-aligned label examples.
