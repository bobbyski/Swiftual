# Swiftual

Swiftual is a Swift terminal UI framework for building rich, keyboard- and mouse-driven command-line applications.

It is inspired by [Textual](https://github.com/Textualize/textual) and the broader [Textual project](https://textual.textualize.io/), while aiming for a Swift-native design built around protocols, Swift concurrency, pure Swift styling, and testable terminal rendering.

## Status

Swiftual is early and evolving. The current implementation includes:

- Protocol-based terminal IO.
- ANSI and VT100 backend selection.
- Virtual canvas rendering.
- Full-screen demo app.
- Main view container.
- Menu bar, menu, and menu item.
- One-row-friendly button.
- Label/static text.
- Keyboard and mouse input parsing.
- User docs that double as a feature test plan.

## Requirements

- macOS 15 or newer.
- Swift 6.3 or newer.
- Local `RichSwift` dependency at `../RichSwift`.

## Run The Demo

```bash
swift run swiftual-demo
```

Manual backend selection:

```bash
swift run swiftual-demo --ansi
swift run swiftual-demo --vt100
```

## Test

```bash
swift test
```

## Documentation

Feature docs are maintained as the framework grows:

- [User Docs](userDocs/index.md)
- [Project Plan And Design](../../Documents/Swiftual_Plan_Design.md)

## Design Principles

- Terminal IO goes through protocols.
- ANSI is the first supported terminal backend.
- VT100 is currently supported through the same ANSI implementation.
- Pure Swift styling is first-class; TCSS-style sheets may be added later as an optional layer.
- Controls should be testable without a real terminal.
- Each new feature should include docs and tests.

## Inspiration

Swiftual is inspired by:

- [Textual GitHub repository](https://github.com/Textualize/textual)
- [Textual documentation site](https://textual.textualize.io/)

Swiftual is not affiliated with Textualize.

## License

Swiftual is released under the MIT License. See [LICENSE](LICENSE).

