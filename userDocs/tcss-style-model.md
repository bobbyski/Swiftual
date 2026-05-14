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
- `TCSSStyle.layout`: optional layout values, including scalar sizes, box spacing, overflow, position, docking, alignment, and layer metadata.
- `TCSSStyle.visual`: optional visual values such as opacity, display, and visibility. These are parsed and cascaded now, but not all of them are rendered by terminal controls yet.
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

- ANSI names: `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`, `bright-black`, `bright-red`, `bright-green`, `bright-yellow`, `bright-blue`, `bright-magenta`, `bright-cyan`, `bright-white`.
- ANSI indexes: `ansi(10)`.
- RGB functions: `rgb(255,0,128)`, `rgb(255 0 128)`, percentage components such as `rgb(100%, 0%, 50%)`, and slash-alpha syntax such as `rgb(255 0 128 / 50%)`.
- RGBA functions: `rgba(255,0,128,0.5)` and percentage alpha such as `rgba(100%, 0%, 50%, 25%)`.
- HSL functions: `hsl(210, 100%, 50%)`, `hsl(210 100% 50%)`, `hsl(210deg 100% 50%)`, and slash-alpha syntax such as `hsl(210 100% 50% / 50%)`. Terminal output stores these as RGB colors.
- HSLA functions: `hsla(210, 100%, 50%, 0.5)`.
- Hex values: `#369` and `#336699`.

Alpha values are parsed and validated now, but the ANSI terminal renderer emits opaque cells. Treat alpha as accepted TCSS syntax with an intentional terminal degradation until a future renderer can blend or preserve transparency.

## Supported Visual Declarations

- `opacity`: accepts `0` through `1` or `0%` through `100%`.
- `text-opacity`: accepts `0` through `1` or `0%` through `100%`.
- `display`: `block` or `none`.
- `visibility`: `visible` or `hidden`.

These visual values are typed and cascaded. `TCSSVisualApplicator` defines the shared interpretation for layout/render decisions: `display: none` does not reserve layout and does not render; `visibility: hidden` reserves layout but does not render. `FlowChild` supports those flags directly, so flow containers can already omit display-none children from space and spacing while leaving hidden children in the layout. Terminal alpha needs an explicit degradation policy, such as palette blending, dim-style fallback, or future vector renderer support.

The TCSS demo includes `12-display-visibility.tcss` as the visible acceptance sheet for this behavior. It hides the label/button panel with `visibility: hidden` so the blank space remains, and removes the container row with `display: none` so later flow content moves upward.

## Supported Layout Declarations

- `width`
- `height`
- `min-width`
- `min-height`
- `max-width`
- `max-height`
- `layout`: `horizontal`, `vertical`, or `grid`.
- `dock`: `top`, `right`, `bottom`, or `left`.
- `align`: horizontal then vertical alignment, such as `center middle`.
- `align-horizontal`: horizontal alignment component: `left`, `center`, or `right`.
- `align-vertical`: vertical alignment component: `top`, `middle`, or `bottom`.
- `content-align`: horizontal then vertical content alignment, such as `right bottom`.
- `content-align-horizontal`: horizontal content-alignment component.
- `content-align-vertical`: vertical content-alignment component.
- `layer`: one layer name.
- `layers`: one or more layer names.
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
- `text-align`: `left`/`start`, `center`/`centre`, `right`/`end`, or `justify`. Current ANSI label rendering treats `justify` as left-aligned until richer text layout exists.
- `divider-width`
- `divider-height`
- `divider-size`: sets both divider dimensions.
- `spacing` / `gap`: fixed cell spacing between flow children in demo/application containers that expose spacing.
- `grid-size`: one positive integer sets columns; two positive integers set columns then rows.
- `grid-gutter`: one non-negative integer sets both vertical and horizontal grid gutters; two values set vertical then horizontal.

Integer values may be plain numbers or use `ch`, `cell`, or `cells` suffixes. Decimal cell values truncate toward zero, including signed values such as `-3.8ch`.
The shared value parser also exposes raw number, raw percentage, single-name, and name-list parsing for future TCSS properties. Raw percentages preserve their numeric ratio, including negative or greater-than-100% values, while individual properties such as `opacity` still apply their own validity range. Name parsing canonicalizes underscores to hyphens, so `overlay_modal` becomes `overlay-modal`.
Width, height, min-width, min-height, max-width, and max-height may also use Textual-style scalar units:

- Unitless numbers and `cell`/`cells`/`ch` values become cell counts. Decimal cell values are truncated toward zero, matching Textual's scalar behavior.
- `%` resolves against the available size on the same axis.
- `fr` participates in proportional remaining-space distribution.
- `w` and `h` resolve against the container width or height.
- `vw` and `vh` resolve against the viewport width or height when a layout container is given a viewport size, otherwise the current container frame is used as the fallback viewport.
- `auto` uses intrinsic size.
- `fill` remains a Swiftual extension for filling remaining space when no `fr` children are present.

Cell values populate the legacy integer `width` and `height` fields; non-cell values populate `widthLength` and `heightLength` for flow containers to resolve against parent space. Minimum and maximum size constraints use the same scalar value model so TCSS can clamp layouts using cells, percentages, fractions, container units, or viewport units.

`margin` maps into `LayoutPreferences.margin` through the shared layout preference applicator. Flow containers now honor that margin during layout: main-axis margins consume space around the child, and cross-axis margins shrink the alignment area before child placement.

Border values currently cover Swiftual's flow-border character presets: `none`, `single`/`solid`, `double`, `heavy`, `dashed`, `rounded`/`round`, `ascii`, and `blank`. Textual aliases that do not have a distinct terminal drawing yet degrade predictably: `outer`, `panel`, `wide`, `tall`, `hkey`, and `vkey` map to `single`; `inner` and `thick` map to `double`; `hidden` maps to `none`. `vector` is reserved for the future vector drawing renderer and currently applies as no visible terminal border. The typed model and cascade preserve border declarations, and `TCSSFlowContainerApplicator` applies them to `FlowContainer`; `TCSSGridApplicator` applies the same border model to `Grid`.

Overflow values support `visible`, `hidden`, `scroll`, and `auto`. The typed model and cascade preserve overflow declarations, and `TCSSFlowContainerApplicator` applies them to `FlowContainer`. Other wrappers will opt into this as their public APIs grow overflow surfaces.

Position values support `relative` and `absolute`, matching Textual's `position` vocabulary. Offsets currently accept signed cell values such as `4 -2`, `4ch -2ch`, `offset-x: -3`, and `offset-y: 8`. Swiftual parses and cascades these values now, but does not apply them to live layout until the Absolute container and offset behavior are designed.

Layout manager and placement values are typed and cascaded now. `layout: vertical` and `layout: horizontal` map to `FlowContainer.axis`; `layout: grid` is preserved for callers that choose a `Grid` surface, and `TCSSGridApplicator` maps fill, spacing/gutter, `grid-size`, `grid-gutter`, padding, border, and frame values onto that surface. `align`, `align-horizontal`, and `align-vertical` map to `FlowAlignment` and are applied by `TCSSFlowContainerApplicator`, `TCSSVerticalApplicator`, and `TCSSHorizontalApplicator`; this controls child placement inside Swiftual flow containers. `dock`, `content-align`, `layer`, and `layers` still preserve Textual-style intent for future layout surfaces. Live application for docking, layer ordering, and content alignment is intentionally deferred until those concepts have pure Swift APIs.

## Diagnostics

The style model keeps parser diagnostics and adds diagnostics for:

- Unknown or cyclic TCSS variable references.
- Declaration-level `!important` values.
- Unsupported properties.
- Unsupported color values.
- Invalid opacity values.
- Unsupported display or visibility values.
- Invalid boolean values.
- Invalid integer values.
- Invalid spacing values.
- Unsupported text alignment or text style values.

## Test Checklist

- Terminal declarations map to `TCSSTerminalStylePatch`, including expanded ANSI flags for bold, dim, italic, underline, strikethrough, inverse, and blink.
- Visual declarations map to `TCSSVisualStyle`; opacity, text opacity, display, and visibility cascade by specificity/source order.
- `TCSSVisualApplicator` reports the expected layout/render behavior for `display` and `visibility`.
- `FlowContainer` honors `FlowChild.reservesLayout` and `FlowChild.shouldRender` so `display: none` and `visibility: hidden` can behave differently in flow layouts.
- Style patches preserve undeclared base values when applied.
- `TCSSStyleLayer` resets previous TCSS-applied state before applying a new patch.
- Top-level `$name: value;` variables resolve inside declaration values before typed parsing. Single-source parsing is source-local; `TCSSStylesheetSourceSet` carries variables forward through enabled sources in deterministic order.
- Declaration-level `!important` is preserved as per-property importance metadata and participates in cascade resolution.
- Hex, RGB, HSL, ANSI indexes, and named colors parse correctly.
- Layout declarations map to typed fields.
- Scalar layout declarations parse for width, height, and min/max constraints.
- Flow spacing declarations parse for containers that opt into TCSS-driven child gaps.
- Margins map into layout preferences and are consumed by flow layout.
- Border declarations parse to Swiftual flow-border presets.
- Overflow declarations parse as shorthand and per-axis properties.
- Position and offset declarations parse and cascade without live layout application yet.
- Layout, dock, alignment, and layer declarations parse and cascade; `layout: vertical`/`horizontal` and `align` apply to flow containers, while `grid`, docking, `content-align`, and layers remain deferred.
- Spacing shorthands parse one to four values.
- Unsupported properties and invalid values report diagnostics.
- The style model does not apply styles to controls yet; cascade and control application are separate steps.
- `TCSSCascade` resolves model rules for a control context before application.
- Multiple active stylesheet sources preserve source order.
- Disabled sources in a `TCSSStylesheetSourceSet` are skipped during parsing and cascade.
- Multi-class selectors require all listed classes to be present on the style context.
- Universal selectors match any context with zero specificity.
- Specificity uses CSS/Textual tuple ordering, so ID selectors outrank class-heavy selectors before source order is considered.
