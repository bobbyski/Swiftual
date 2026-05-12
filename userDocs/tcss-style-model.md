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

For app-level theme stacks, prefer a source set. Source sets keep source kind metadata and can retain disabled/generated sources without letting disabled rules enter the cascade.

```swift
let sourceSet = TCSSStylesheetSourceSet(sources: [
    TCSSStylesheetSource(name: "base.tcss", source: baseSource, kind: .file),
    TCSSStylesheetSource(name: "generated", source: generatedSource, kind: .generated, isEnabled: false),
    TCSSStylesheetSource(name: "inline", source: inlineSource, kind: .inline)
])

let model = TCSSStyleModelBuilder().parse(sourceSet)
```

## Model Types

- `TCSSStyleModel.rules`: style rules with selectors and typed style data.
- `TCSSStyleModel.diagnostics`: parser and style-model diagnostics.
- `TCSSStyleRule.selectors`: selectors from the parsed rule.
- `TCSSStyleRule.style`: typed style data.
- `TCSSStyle.terminalStyle`: optional `TerminalStyle` patch values.
- `TCSSStyle.layout`: optional layout and future control style values.
- `TCSSStylesheetSource`: named TCSS source used when parsing multiple active files. Sources also carry kind metadata and an enabled flag.
- `TCSSStylesheetSourceSet`: ordered source collection for theme stacks, generated styles, inline overrides, and demo/file-picker inputs.
- `TCSSTerminalStylePatch.applied(to:)`: overlays declared terminal values on a pure Swift base style.
- `TCSSStyleLayer`: stores a pure Swift default value plus the currently styled value so callers can reset before applying a new stylesheet stack.

## Supported Terminal Style Declarations

- `color` / `foreground`: foreground color.
- `background` / `background-color`: background color.
- `text-style`: supports `bold`, `dim`, `italic`, `underline`, `strike`, `strikethrough`, `inverse`, `reverse`, `blink`, `none`, `plain`, and `normal`.
- `bold`: boolean value.
- `dim`: boolean value.
- `italic`: boolean value.
- `underline`: boolean value.
- `strike` / `strikethrough`: boolean value.
- `inverse`: boolean value.
- `blink`: boolean value.

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
- `border`: `none`, `single`/`solid`, `double`, `dashed`, `rounded`, `ascii`, or `vector`.
- `overflow`: one value applies to both axes; two values apply to x then y.
- `overflow-x`
- `overflow-y`
- `position`: `relative` or `absolute`.
- `offset`: two signed cell offsets: x then y.
- `offset-x`
- `offset-y`
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

Border values currently cover Swiftual's flow-border character presets: `none`, `single`/`solid`, `double`, `dashed`, `rounded`, and `ascii`. `vector` is reserved for the future vector drawing renderer and currently applies as no visible terminal border. The typed model and cascade preserve border declarations, and `TCSSFlowContainerApplicator` applies them to `FlowContainer`.

Overflow values support `visible`, `hidden`, `scroll`, and `auto`. The typed model and cascade preserve overflow declarations, and `TCSSFlowContainerApplicator` applies them to `FlowContainer`. Other wrappers will opt into this as their public APIs grow overflow surfaces.

Position values support `relative` and `absolute`, matching Textual's `position` vocabulary. Offsets currently accept signed cell values such as `4 -2`, `4ch -2ch`, `offset-x: -3`, and `offset-y: 8`. Swiftual parses and cascades these values now, but does not apply them to live layout until the Absolute container and offset behavior are designed.

## Diagnostics

The style model keeps parser diagnostics and adds diagnostics for:

- Unsupported properties.
- Unsupported color values.
- Invalid boolean values.
- Invalid integer values.
- Invalid spacing values.
- Unsupported text alignment or text style values.

## Test Checklist

- Terminal declarations map to `TCSSTerminalStylePatch`, including expanded ANSI flags for bold, dim, italic, underline, strikethrough, inverse, and blink.
- Style patches preserve undeclared base values when applied.
- `TCSSStyleLayer` resets previous TCSS-applied state before applying a new patch.
- Hex, RGB, ANSI indexes, and named colors parse correctly.
- Layout declarations map to typed fields.
- Scalar layout declarations parse for width, height, and min/max constraints.
- Flow spacing declarations parse for containers that opt into TCSS-driven child gaps.
- Border declarations parse to Swiftual flow-border presets.
- Overflow declarations parse as shorthand and per-axis properties.
- Position and offset declarations parse and cascade without live layout application yet.
- Spacing shorthands parse one to four values.
- Unsupported properties and invalid values report diagnostics.
- The style model does not apply styles to controls yet; cascade and control application are separate steps.
- `TCSSCascade` resolves model rules for a control context before application.
- Multiple active stylesheet sources preserve source order.
- Disabled sources in a `TCSSStylesheetSourceSet` are skipped during parsing and cascade.
- Multi-class selectors require all listed classes to be present on the style context.
