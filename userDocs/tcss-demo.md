# TCSS Demo Harness

`swiftual-tcss-demo` is a separate executable in `Code/SwiftualTCSSDemo` for testing optional stylesheet support without disturbing the frozen pure-Swift demo. It duplicates the current showcase and adds a right-side panel for choosing sample TCSS files.

## Running

```bash
cd Code/SwiftualTCSSDemo
swift run swiftual-tcss-demo
```

Backend selection flags match the normal demo:

```bash
swift run swiftual-tcss-demo --ansi
swift run swiftual-tcss-demo --vt100
```

The pure Swift baseline demo lives in `Code/SwiftualDemo` and runs with `swift run swiftual-demo`.

## Layout

- The original demo remains on the left as the baseline.
- The original demo and TCSS panel are separated by a draggable `HorizontalSplitView`.
- The Rich Log lives in the original demo's bottom `VerticalSplitView`, matching the baseline demo structure again.
- The right panel starts below the blue menu bar.
- A selector at the top chooses a sample stylesheet feature set.
- The demo opens on `00-baseline.tcss`; switch to `10-edge-to-edge-flow.tcss` when you want to exercise percentage sizing across every visible control group.
- A scrollable source preview below shows the selected stylesheet text with RichSwift syntax highlighting and line numbers.
- The panel is intentionally separate so stylesheet parsing and application can be tested across the whole control set without changing the frozen baseline demo.

## Included Stylesheets

- `00-baseline.tcss`: captures the frozen Swift styling.
- `01-current-target.tcss`: scratch/current-step stylesheet for isolating whichever controls we are actively implementing.
- `02-pseudo-states.tcss`: pseudo-state feature set such as `:focus`, `:checked`, `:on`, `:open`, and `:selected`.
- `03-combinators.tcss`: child and descendant selector feature set.
- `04-big.tcss`: large but bounded sizing requests for layout stress testing.
- `05-small.tcss`: tiny sizing requests for clipping and minimum-size edge cases.
- `06-that70sShow.tcss`: intentionally obnoxious bright-color flexibility demo. Never do this, but it is good to know you can.
- `07-percent-flow.tcss`: percentage and fill-based outer demo layout rules for testing flexible flow containers.

## Keyboard Behavior

- The underlying frozen demo keeps its current keyboard behavior.
- When the stylesheet selector is focused, Enter or Space opens it.
- Up and Down move through stylesheet choices.
- Enter chooses the highlighted stylesheet.
- The source preview can scroll with Up and Down when focused.

## Mouse Behavior

- Click the stylesheet selector to open it.
- Click a stylesheet name to switch the displayed source text.
- Mouse wheel scrolls the source preview.
- Dragging the blue divider is temporarily disabled while the scalar-resize acceptance test is isolated.
- Mouse and keyboard behavior outside the right panel continues to route to the frozen baseline demo.

## File Structure

- App loop: `Code/SwiftualTCSSDemo/Sources/SwiftualTCSSDemo/TSSDemoApplication.swift`
- TCSS demo state: `Code/SwiftualTCSSDemo/Sources/SwiftualTCSSDemo/TSSDemoView.swift`
- Side-panel input routing: `Code/SwiftualTCSSDemo/Sources/SwiftualTCSSDemo/TSSDemoView+Input.swift`
- TCSS application hooks: `Code/SwiftualTCSSDemo/Sources/SwiftualTCSSDemo/TSSDemoView+StyleApplication.swift`
- Right-side selector/source panel: `Code/SwiftualTCSSDemo/Sources/SwiftualTCSSDemo/TSSDemoView+Panel.swift`
- Built-in sample stylesheets: `Code/SwiftualTCSSDemo/Sources/SwiftualTCSSDemo/TSSDemoView+Stylesheets.swift`

## Current Scope

The harness switches stylesheet source, parses it, applies supported declarations to matching controls, and logs the selected file. TCSS files are feature-set tests and apply across the whole control set where Swiftual has implemented the matching style hook. `01-current-target.tcss` is the exception: it is the rolling scratch file for the isolated controls we are targeting in the current implementation step.

## Test Checklist

- `swiftual-tcss-demo` builds as a separate executable.
- Right-side panel renders without changing `swiftual-demo`.
- Selector renders available stylesheet file names.
- Switching the selector updates the source preview.
- Switching a stylesheet logs the selected file.
- Baseline demo controls still render and handle events.
