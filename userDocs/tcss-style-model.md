# TCSS Style Model

`TCSSStyleModelBuilder` converts parsed TCSS declarations into typed Swift values. It is still optional: controls can continue to be styled entirely in pure Swift.

## Creation

```swift
let model = TCSSStyleModelBuilder().parse("""
Button:focus {
    background: blue;
    color: bright-white;
    text-style: bold;
    height: 1;
}
""")
```

You can also build from an existing parsed stylesheet:

```swift
let stylesheet = TCSSParser().parse(source)
let model = TCSSStyleModelBuilder().build(from: stylesheet)
```

## Model Types

- `TCSSStyleModel.rules`: style rules with selectors and typed style data.
- `TCSSStyleModel.diagnostics`: parser and style-model diagnostics.
- `TCSSStyleRule.selectors`: selectors from the parsed rule.
- `TCSSStyleRule.style`: typed style data.
- `TCSSStyle.terminalStyle`: optional `TerminalStyle` patch values.
- `TCSSStyle.layout`: optional layout and future control style values.
- `TCSSTerminalStylePatch.applied(to:)`: overlays declared terminal values on a pure Swift base style.

## Supported Terminal Style Declarations

- `color` / `foreground`: foreground color.
- `background` / `background-color`: background color.
- `text-style`: supports `bold`, `inverse`, `reverse`, `none`, `plain`, and `normal`.
- `bold`: boolean value.
- `inverse`: boolean value.

Supported colors:

- ANSI names: `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`, `bright-black`, `bright-white`.
- ANSI indexes: `ansi(10)`.
- RGB functions: `rgb(255,0,128)`.
- Hex values: `#369` and `#336699`.

## Supported Layout Declarations

- `width`
- `height`
- `min-width`
- `min-height`
- `max-width`
- `max-height`
- `padding`
- `margin`
- `text-align`: `left`, `center`, or `right`.
- `divider-width`
- `divider-height`
- `divider-size`: sets both divider dimensions.

Integer values may be plain numbers or use `ch`, `cell`, or `cells` suffixes.

## Diagnostics

The style model keeps parser diagnostics and adds diagnostics for:

- Unsupported properties.
- Unsupported color values.
- Invalid boolean values.
- Invalid integer values.
- Invalid spacing values.
- Unsupported text alignment or text style values.

## Test Checklist

- Terminal declarations map to `TCSSTerminalStylePatch`.
- Style patches preserve undeclared base values when applied.
- Hex, RGB, ANSI indexes, and named colors parse correctly.
- Layout declarations map to typed fields.
- Spacing shorthands parse one to four values.
- Unsupported properties and invalid values report diagnostics.
- The style model does not apply styles to controls yet; cascade and control application are separate steps.
- `TCSSCascade` resolves model rules for a control context before application.
