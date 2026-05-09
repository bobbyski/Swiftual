# Styling

Swiftual styling is pure Swift first. TCSS can be added later as an optional layer, but controls must be usable and styleable without any stylesheet dependency.

## Core Types

```swift
public enum TerminalColor {
    case ansi(Int)
    case rgb(UInt8, UInt8, UInt8)
}
```

```swift
public struct TerminalStyle {
    public var foreground: TerminalColor?
    public var background: TerminalColor?
    public var bold: Bool
    public var inverse: Bool
}
```

## Built-In Colors

Current convenience colors:

- `.black`
- `.red`
- `.green`
- `.yellow`
- `.blue`
- `.magenta`
- `.cyan`
- `.white`
- `.brightBlack`
- `.brightWhite`

## ANSI Mapping

Styles are converted to ANSI SGR codes by the active backend. Standard color indexes `0...7` map to normal ANSI colors, `8...15` map to bright ANSI colors, and other indexes map through 256-color SGR codes.

## Test Checklist

- Foreground colors emit foreground SGR codes.
- Background colors emit background SGR codes.
- Bold emits SGR `1`.
- Changing styles in adjacent cells emits reset and new style codes.
- Pure Swift style values are enough to render menus and buttons.

