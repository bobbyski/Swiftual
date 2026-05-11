# TCSS Architecture

TCSS is optional in Swiftual. Pure Swift styles and layout preferences remain the source of truth; TCSS layers on top when an app chooses stylesheet-driven styling.

This page defines the intended framework boundaries so demo code does not become the TCSS architecture.

## Pipeline

```text
source text
  -> TCSSParser
  -> TCSSStylesheet
  -> TCSSStyleModelBuilder
  -> TCSSStyleModel
  -> TCSSStyleResolver / TCSSCascade
  -> TCSSStyle
  -> control-specific applicator
  -> Swiftual control state
```

## Boundaries

- `TCSSStylesheetSource`: names a stylesheet and stores its source text. Source order is deterministic and affects cascade wins when specificity ties.
- `TCSSStylesheetProviding`: protocol for objects that can provide a `TCSSStylesheetSource`. Demos, file pickers, generated themes, and app-level theme managers can conform without changing parser or cascade code.
- `TCSSParser`: raw syntax parser. It should know TCSS grammar, selectors, declarations, comments, and diagnostics. It should not know Swiftual controls.
- `TCSSStyleModelBuilder`: converts parsed declarations into typed semantic style values. This is where raw strings become colors, lengths, booleans, box edges, text alignment, and future typed TCSS values.
- `TCSSStyleModel`: stores typed rules plus diagnostics. Rules remember optional source names and source indexes so future diagnostics can point back to the active stylesheet.
- `TCSSCascade`: applies selector matching, specificity, and source order to produce a `TCSSStyle` for one `TCSSStyleContext`.
- `TCSSStyleResolver`: public convenience boundary that owns a model and exposes `style(for:)`. Apps should usually depend on this instead of manually wiring parser, builder, and cascade.
- `TCSSStyleApplying`: protocol for control-specific applicators. A button applicator should know how a `TCSSStyle` maps onto `Button`; the demo harness should not need bespoke knowledge of every control forever.
- `TCSSLayoutApplicator`: shared conversion from `TCSSLayoutStyle` into control frames and `LayoutPreferences`.
- `TCSSButtonApplicator`, `TCSSLabelApplicator`, `TCSSProgressBarApplicator`, `TCSSTextInputApplicator`, `TCSSCheckboxApplicator`, `TCSSSwitchApplicator`, `TCSSSelectApplicator`, `TCSSScrollViewApplicator`, `TCSSRichLogApplicator`, `TCSSDataTableApplicator`, `TCSSTreeApplicator`, `TCSSModalApplicator`, `TCSSFlowContainerApplicator`, `TCSSVerticalApplicator`, `TCSSHorizontalApplicator`, and `TCSSCommandPaletteApplicator`: first reusable control applicators. These replaced the matching demo-local styling code and set the pattern for the remaining controls.

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
- `TCSSLabelApplicator`: patches style, frame layout values, and text alignment.
- `TCSSProgressBarApplicator`: patches track, complete, pulse, text, and frame layout values.
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

Remaining demo-specific applicators should move over in small passes so each control's mapping can be tested. Worker demo progress and demo panel preferences remain demo-owned for now because they do not yet map cleanly to standalone framework controls.

## Reset And Fallback Rule

When active stylesheet sources change:

- Start from pure Swift defaults.
- Resolve TCSS for each style context.
- Apply only the properties present in the resolved patch.
- Do not let old TCSS-applied values leak into the next stylesheet selection.

The current TCSS demo still has demo-specific reset/application code. The next architecture step should move that behavior into reusable applicators.

## Test Checklist

- Multiple stylesheet sources preserve source order.
- Rules retain source name and source index metadata.
- `TCSSStyleResolver` exposes model diagnostics.
- `TCSSStyleResolver.style(for:)` returns the same result as `TCSSCascade`.
- Control applicators patch pure Swift defaults rather than replacing unrelated properties.
- Button, label, progress bar, text input, checkbox, switch, select, scroll view, rich log, data table, tree, modal, flow container, vertical container, horizontal container, and command palette applicators are tested directly.
- Switching active stylesheets starts from defaults and does not leak old values.
