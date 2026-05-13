# TCSS Architecture

TCSS is optional in Swiftual. Pure Swift styles and layout preferences remain the source of truth; TCSS layers on top when an app chooses stylesheet-driven styling.

This page defines the intended framework boundaries so demo code does not become the TCSS architecture.

## Pipeline

```text
source text
  -> TCSSStylesheetSourceSet
  -> TCSSParser
  -> TCSSStylesheet
  -> TCSSStyleModelBuilder
  -> TCSSValueParser
  -> TCSSStyleModel
  -> TCSSStyleResolver / TCSSCascade
  -> TCSSStyle
  -> control-specific applicator
  -> Swiftual control state
```

## Boundaries

- `TCSSStylesheetSource`: names a stylesheet, stores its source text, identifies its kind (`swiftDefaults`, `file`, `inline`, `generated`, or `demo`), and tracks whether it is enabled.
- `TCSSStylesheetSourceSet`: stores the active source stack, filters disabled sources before parsing, preserves deterministic source order, and can produce a combined source preview for test harnesses or tooling.
- `TCSSStylesheetProviding`: protocol for objects that can provide a `TCSSStylesheetSource`. Demos, file pickers, generated themes, and app-level theme managers can conform without changing parser or cascade code.
- `TCSSParser`: raw syntax parser. It should know TCSS grammar, selectors, declarations, comments, and diagnostics. It should not know Swiftual controls.
- `TCSSStyleModelBuilder`: converts parsed declarations into typed semantic style values. It owns declaration-to-property mapping and delegates individual value parsing to `TCSSValueParser`.
- `TCSSValueParser`: converts raw declaration values into typed semantic values such as colors, booleans, scalar lengths, signed offsets, opacity values, display/visibility states, box edges, border kinds, overflow policies, position values, layout kinds, dock edges, alignment pairs, layer names, text alignment, and expanded ANSI text style patches. Future TCSS value families should start here rather than in control code or demo code.
- `TCSSStyleModel`: stores typed rules plus diagnostics. Rules remember optional source names and source indexes so future diagnostics can point back to the active stylesheet.
- `TCSSLayoutStyle`: stores layout-facing declarations such as scalar dimensions, min/max constraints, padding, margin, overflow, border, position, offsets, spacing, layout kind, dock, alignment, and layer metadata. Some of these values are already applied by flow/container applicators; others are preserved for future layout surfaces.
- `TCSSVisualStyle`: stores non-layout visual values such as `opacity`, `text-opacity`, `display`, and `visibility`. These are parsed and cascaded now; terminal rendering behavior is intentionally deferred until Swiftual has clear alpha/degradation and layout omission strategies.
- `TCSSStyleContext` and `TCSSStyleContextNode`: describe the styled control plus its nearest-parent-first ancestor path. This is the DOM-light selector matching surface for type, ID, class, pseudo-state, child, and descendant selectors.
- `TCSSCascade`: applies selector matching, specificity, and source order to produce a `TCSSStyle` for one `TCSSStyleContext`.
- `TCSSStyleResolver`: public convenience boundary that owns a model and exposes `style(for:)`. Apps should usually depend on this instead of manually wiring parser, builder, and cascade.
- `TCSSStyleLayer`: tiny reset/fallback helper for state that must start from a pure Swift default before a TCSS patch is applied. It exists so stylesheet changes cannot accidentally inherit values from the previous stylesheet.
- `TCSSStyleApplying`: protocol for control-specific applicators. A button applicator should know how a `TCSSStyle` maps onto `Button`; the demo harness should not need bespoke knowledge of every control forever.
- `TCSSVisualApplicator`: shared interpretation for visual flow control. `display: none` does not reserve layout and does not render; `visibility: hidden` reserves layout but does not render. It can produce `FlowChild` values with those flags already applied.
- `TCSSLayoutApplicator`: shared conversion from `TCSSLayoutStyle` into control frames, `LayoutPreferences`, and flow alignment values.
- `TCSSLayoutPreferencesApplicator`: shared conversion from a resolved `TCSSStyle` into standalone `LayoutPreferences` and spacing values for panel-like layout surfaces.
- `TCSSButtonApplicator`, `TCSSLabelApplicator`, `TCSSProgressBarApplicator`, `TCSSProgressStyleSetApplicator`, `TCSSTextInputApplicator`, `TCSSCheckboxApplicator`, `TCSSSwitchApplicator`, `TCSSSelectApplicator`, `TCSSScrollViewApplicator`, `TCSSRichLogApplicator`, `TCSSDataTableApplicator`, `TCSSTreeApplicator`, `TCSSModalApplicator`, `TCSSFlowContainerApplicator`, `TCSSVerticalApplicator`, `TCSSHorizontalApplicator`, `TCSSHorizontalSplitViewApplicator`, `TCSSVerticalSplitViewApplicator`, and `TCSSCommandPaletteApplicator`: first reusable control applicators. These replaced the matching demo-local styling code and set the pattern for the remaining controls.

## Current Source Order Rule

When multiple stylesheet sources are active, later sources win ties with the same selector specificity.

Example:

```swift
let resolver = TCSSStyleResolver(sources: [
    TCSSStylesheetSource(name: "base.tcss", source: "Button { background: blue; }"),
    TCSSStylesheetSource(name: "theme.tcss", source: "Button { background: green; }")
])
```

For `Button`, the resolved background is green because `theme.tcss` is later in source order.

Apps that manage multiple optional sources should prefer a source set:

```swift
let sourceSet = TCSSStylesheetSourceSet(sources: [
    TCSSStylesheetSource(name: "defaults", source: "", kind: .swiftDefaults),
    TCSSStylesheetSource(name: "base.tcss", source: baseSource, kind: .file),
    TCSSStylesheetSource(name: "generated", source: generatedSource, kind: .generated, isEnabled: false),
    TCSSStylesheetSource(name: "inline", source: inlineSource, kind: .inline)
])

let resolver = TCSSStyleResolver(sourceSet: sourceSet)
```

Disabled sources remain available to the app as state, but they are not parsed or cascaded.

## Control Application Rule

Controls should keep their pure Swift defaults. TCSS should patch those defaults rather than replace them wholesale.

Future control applicators should follow this pattern:

```swift
struct ButtonTCSSApplicator: TCSSStyleApplying {
    func apply(_ style: TCSSStyle, to target: inout Button) {
        target.style = style.terminalStyle.applied(to: target.style)
    }
}
```

That keeps styling local to the control and lets alternate demos, app frameworks, or declarative wrappers reuse the same behavior.

Current reusable applicators:

- `TCSSVisualApplicator`: reports whether a style should reserve layout and whether it should render, and can create `FlowChild` values with the correct `display`/`visibility` flags.
- `TCSSButtonApplicator`: patches normal, focused, disabled, and frame layout values.
- `TCSSLayoutPreferencesApplicator`: patches `LayoutPreferences` and exposes resolved spacing for layout-only demo panels or future framework surfaces.
- `TCSSLabelApplicator`: patches style, frame layout values, and text alignment.
- `TCSSProgressBarApplicator`: patches track, complete, pulse, text, and frame layout values.
- `TCSSProgressStyleSetApplicator`: patches track, complete, text, and layout preferences for progress-like surfaces that are not standalone controls yet.
- `TCSSTextInputApplicator`: patches normal, focused, placeholder, cursor, and frame layout values.
- `TCSSCheckboxApplicator`: patches normal, focused, checked, focused checked, disabled, and frame layout values.
- `TCSSSwitchApplicator`: patches off, on, focused off, focused on, disabled, and frame layout values.
- `TCSSSelectApplicator`: patches closed, focused, open, option, selected option, disabled, and frame layout values.
- `TCSSScrollViewApplicator`: patches fill, content, scrollbar, thumb, scrollbar width, and frame layout values.
- `TCSSRichLogApplicator`: patches fill, title, and frame layout values.
- `TCSSDataTableApplicator`: patches table row, header, alternate row, selected row, focused selected row, and frame layout values.
- `TCSSTreeApplicator`: patches fill, row, selected, focused selected, branch, scrollbar, thumb, scrollbar width, and frame layout values.
- `TCSSModalApplicator`: patches panel, overlay, title, normal button, focused button, disabled button, and frame layout values.
- `TCSSFlowContainerApplicator`: patches fill, spacing, padding, border, overflow, axis for `layout: vertical`/`horizontal`, alignment, and frame layout values for the core `FlowContainer`. `layout: grid` remains deferred, and `border: vector` is intentionally accepted but rendered as no terminal border until the vector renderer exists.
- `TCSSVerticalApplicator`: patches fill, spacing, alignment, and frame layout values for `Vertical`.
- `TCSSHorizontalApplicator`: patches fill, spacing, alignment, and frame layout values for `Horizontal`.
- `TCSSHorizontalSplitViewApplicator`: patches divider style and divider width for `HorizontalSplitView`.
- `TCSSVerticalSplitViewApplicator`: patches divider style and divider height for `VerticalSplitView`.
- `TCSSCommandPaletteApplicator`: patches panel, title, input, normal item, highlighted item, disabled item, and frame layout values.

Remaining demo-specific applicators should move over in small passes so each control's mapping can be tested. The TCSS demo still owns which panel preference each demo-only selector targets, but the style-to-preference mapping itself now lives in the framework.

## Reset And Fallback Rule

When active stylesheet sources change:

- Start from pure Swift defaults.
- Resolve TCSS for each style context.
- Apply only the properties present in the resolved patch.
- Do not let old TCSS-applied values leak into the next stylesheet selection.

`TCSSStyleLayer` captures that rule for reusable state:

```swift
var layer = TCSSStyleLayer(defaultValue: Button.defaultStyle, value: button.style)
layer.resetAndApply { style in
    style = patch.applied(to: style)
}
button.style = layer.value
```

The TCSS demo uses this helper while resetting demo-owned surfaces before applying the newly selected source stack. Framework controls should still prefer typed applicators for actual style mapping; the layer is the guardrail that keeps fallback state explicit.

## Test Checklist

- Multiple stylesheet sources preserve source order.
- Source sets preserve source kind metadata, omit disabled sources from parsing, and expose enabled source names for diagnostics or UI.
- Rules retain source name and source index metadata.
- `TCSSStyleResolver` exposes model diagnostics.
- `TCSSStyleResolver.style(for:)` returns the same result as `TCSSCascade`.
- `TCSSStyleContext` ancestor paths let child selectors require a direct parent and descendant selectors match deeper ancestors.
- `TCSSValueParser` covers color, boolean, scalar length, signed offset, box edge, border, overflow, position, layout kind, dock, alignment, layer names, text alignment, and text style conversion directly.
- Control applicators patch pure Swift defaults rather than replacing unrelated properties.
- Visual behavior helper, layout preferences, button, label, progress bar, progress style set, text input, checkbox, switch, select, scroll view, rich log, data table, tree, modal, flow container, vertical container, horizontal container, and command palette applicators are tested directly, including flow alignment mapping where the target exposes it.
- Flow containers distinguish `display: none` from `visibility: hidden`: display-none children do not consume spacing or layout space, while hidden children reserve space but skip rendering.
- `TCSSStyleLayer` resets to pure Swift defaults before reapplying a different TCSS patch.
- Switching active stylesheets starts from defaults and does not leak old values.
