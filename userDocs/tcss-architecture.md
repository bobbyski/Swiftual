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
- `TCSSValueParser`: converts raw declaration values into typed semantic values such as colors, booleans, scalar lengths, box edges, text alignment, and text style patches. Future TCSS value families should start here rather than in control code or demo code.
- `TCSSStyleModel`: stores typed rules plus diagnostics. Rules remember optional source names and source indexes so future diagnostics can point back to the active stylesheet.
- `TCSSCascade`: applies selector matching, specificity, and source order to produce a `TCSSStyle` for one `TCSSStyleContext`.
- `TCSSStyleResolver`: public convenience boundary that owns a model and exposes `style(for:)`. Apps should usually depend on this instead of manually wiring parser, builder, and cascade.
- `TCSSStyleApplying`: protocol for control-specific applicators. A button applicator should know how a `TCSSStyle` maps onto `Button`; the demo harness should not need bespoke knowledge of every control forever.
- `TCSSLayoutApplicator`: shared conversion from `TCSSLayoutStyle` into control frames and `LayoutPreferences`.
- `TCSSLayoutPreferencesApplicator`: shared conversion from a resolved `TCSSStyle` into standalone `LayoutPreferences` and spacing values for panel-like layout surfaces.
- `TCSSButtonApplicator`, `TCSSLabelApplicator`, `TCSSProgressBarApplicator`, `TCSSProgressStyleSetApplicator`, `TCSSTextInputApplicator`, `TCSSCheckboxApplicator`, `TCSSSwitchApplicator`, `TCSSSelectApplicator`, `TCSSScrollViewApplicator`, `TCSSRichLogApplicator`, `TCSSDataTableApplicator`, `TCSSTreeApplicator`, `TCSSModalApplicator`, `TCSSFlowContainerApplicator`, `TCSSVerticalApplicator`, `TCSSHorizontalApplicator`, and `TCSSCommandPaletteApplicator`: first reusable control applicators. These replaced the matching demo-local styling code and set the pattern for the remaining controls.

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
- `TCSSFlowContainerApplicator`: patches fill, spacing, padding, and frame layout values for the core `FlowContainer`.
- `TCSSVerticalApplicator`: patches fill, spacing, and frame layout values for `Vertical`.
- `TCSSHorizontalApplicator`: patches fill, spacing, and frame layout values for `Horizontal`.
- `TCSSCommandPaletteApplicator`: patches panel, title, input, normal item, highlighted item, disabled item, and frame layout values.

Remaining demo-specific applicators should move over in small passes so each control's mapping can be tested. The TCSS demo still owns which panel preference each demo-only selector targets, but the style-to-preference mapping itself now lives in the framework.

## Reset And Fallback Rule

When active stylesheet sources change:

- Start from pure Swift defaults.
- Resolve TCSS for each style context.
- Apply only the properties present in the resolved patch.
- Do not let old TCSS-applied values leak into the next stylesheet selection.

The current TCSS demo still has demo-specific reset/application code. The next architecture step should move that behavior into reusable applicators.

## Test Checklist

- Multiple stylesheet sources preserve source order.
- Source sets preserve source kind metadata, omit disabled sources from parsing, and expose enabled source names for diagnostics or UI.
- Rules retain source name and source index metadata.
- `TCSSStyleResolver` exposes model diagnostics.
- `TCSSStyleResolver.style(for:)` returns the same result as `TCSSCascade`.
- `TCSSValueParser` covers color, boolean, scalar length, box edge, text alignment, and text style conversion directly.
- Control applicators patch pure Swift defaults rather than replacing unrelated properties.
- Layout preferences, button, label, progress bar, progress style set, text input, checkbox, switch, select, scroll view, rich log, data table, tree, modal, flow container, vertical container, horizontal container, and command palette applicators are tested directly.
- Switching active stylesheets starts from defaults and does not leak old values.
