# Main View Container

`MainViewContainer` is demo-only code, not framework API. It lives in `Code/SwiftualDemo/Sources/SwiftualDemo` and is duplicated in `Code/SwiftualTCSSDemo/Sources/SwiftualTCSSDemo` as the baseline surface for stylesheet testing.

It owns the menu bar, a grey full-screen body, the demo controls, and a bottom rich-log pane.

## Behavior

The container renders:

- A blue menu bar at the top row.
- A grey body filling the remaining terminal area.
- Demo text in the body.
- Demo controls in the top pane.
- A fixed `VerticalSplitView` divider.
- A `RichLog` in the bottom pane.
- A `Clamp log` switch that toggles whether the vertical split honors minimum pane sizes.

## Focus

The current focus enum is:

```swift
public enum MainViewFocus {
    case menuBar
    case button
    case textInput
    case checkbox
    case `switch`
    case select
    case scrollView
    case modalButton
    case progressButton
    case dataTable
    case tree
    case commandPaletteButton
    case splitClampSwitch
    case workerButton
}
```

`Tab` moves focus through the interactive controls when the menu is not open.

## Input Routing

- Menu bar focus sends events to `MenuBar`.
- Button focus sends events to `Button`.
- Mouse clicks focus and route to the control under the pointer.
- The modal and command palette render as overlays when active.
- The rich log records actions but is not currently interactive.

## File Structure

- State and defaults: `Code/SwiftualDemo/Sources/SwiftualDemo/MainViewContainer.swift`
- Keyboard and mouse routing: `Code/SwiftualDemo/Sources/SwiftualDemo/MainViewContainer+Input.swift`
- Rendering: `Code/SwiftualDemo/Sources/SwiftualDemo/MainViewContainer+Rendering.swift`
- Layout: `Code/SwiftualDemo/Sources/SwiftualDemo/MainViewContainer+Layout.swift`
- Rich log messages: `Code/SwiftualDemo/Sources/SwiftualDemo/MainViewContainer+Logging.swift`
- Focus order: `Code/SwiftualDemo/Sources/SwiftualDemo/MainViewFocus.swift`
- Layout result type: `Code/SwiftualDemo/Sources/SwiftualDemo/ShowcaseLayout.swift`

## Test Checklist

- The body fills all rows below the menu bar with the configured background.
- The menu bar renders over the body on row zero.
- The fixed vertical split divider renders above the bottom log pane.
- The rich log renders in the bottom split pane.
- The `Clamp log` switch toggles the split view's `isClamped` setting for short-screen and edge-case tests.
- `Tab` can move focus through the controls.
- `Enter` on a focused activatable control triggers it.
- Mouse click inside a control frame activates or focuses it.
