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

Multiple active stylesheet sources can be parsed in deterministic order. Later equal-specificity declarations win, while higher-specificity selectors still override lower-specificity declarations from later sources.

```swift
let model = TCSSStyleModelBuilder().parse([
    TCSSStylesheetSource(name: "base.tcss", source: baseSource),
    TCSSStylesheetSource(name: "theme.tcss", source: themeSource),
    TCSSStylesheetSource(name: "target.tcss", source: targetSource)
])
```

## Model Types

- `TCSSStyleModel.rules`: style rules with selectors and typed style data.
- `TCSSStyleModel.diagnostics`: parser and style-model diagnostics.
- `TCSSStyleRule.selectors`: selectors from the parsed rule.
- `TCSSStyleRule.style`: typed style data.
- `TCSSStyle.terminalStyle`: optional `TerminalStyle` patch values.
- `TCSSStyle.layout`: optional layout and future control style values.
- `TCSSStylesheetSource`: named TCSS source used when parsing multiple active files.
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
- `spacing` / `gap`: fixed cell spacing between flow children in demo/application containers that expose spacing.

Integer values may be plain numbers or use `ch`, `cell`, or `cells` suffixes.
Width, height, min-width, min-height, max-width, and max-height may also use Textual-style scalar units:

- Unitless numbers and `cell`/`cells`/`ch` values become cell counts. Decimal cell values are truncated toward zero, matching Textual's scalar behavior.
- `%` resolves against the available size on the same axis.
- `fr` participates in proportional remaining-space distribution.
- `w` and `h` resolve against the container width or height.
- `vw` and `vh` resolve against the viewport width or height when a layout container is given a viewport size, otherwise the current container frame is used as the fallback viewport.
- `auto` uses intrinsic size.
- `fill` remains a Swiftual extension for filling remaining space when no `fr` children are present.

Cell values populate the legacy integer `width` and `height` fields; non-cell values populate `widthLength` and `heightLength` for flow containers to resolve against parent space. Minimum and maximum size constraints use the same scalar value model so TCSS can clamp layouts using cells, percentages, fractions, container units, or viewport units.

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
- Scalar layout declarations parse for width, height, and min/max constraints.
- Flow spacing declarations parse for containers that opt into TCSS-driven child gaps.
- Spacing shorthands parse one to four values.
- Unsupported properties and invalid values report diagnostics.
- The style model does not apply styles to controls yet; cascade and control application are separate steps.
- `TCSSCascade` resolves model rules for a control context before application.
- Multiple active stylesheet sources preserve source order.
- Multi-class selectors require all listed classes to be present on the style context.
