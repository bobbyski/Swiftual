# TCSS/TSS Demo Harness

`swiftual-tss-demo` is a separate executable for testing optional stylesheet support without disturbing the frozen pure-Swift demo. It duplicates the current showcase and adds a right-side panel for choosing sample TCSS/TSS files.

## Running

```bash
swift run swiftual-tss-demo
```

Backend selection flags match the normal demo:

```bash
swift run swiftual-tss-demo --ansi
swift run swiftual-tss-demo --vt100
```

## Layout

- The original demo remains on the left as the baseline.
- The original demo and right panel are separated by a draggable `HorizontalSplitView` divider.
- The right panel starts below the blue menu bar.
- A selector at the top chooses a sample stylesheet feature set.
- A scrollable source preview below shows the selected stylesheet text with RichSwift syntax highlighting and line numbers.
- The panel is intentionally separate so stylesheet parsing and application can be tested across the whole control set without changing the frozen baseline demo.

## Included Stylesheets

- `00-baseline.tcss`: captures the frozen Swift styling.
- `01-current-target.tcss`: scratch/current-step stylesheet for isolating whichever controls we are actively implementing.
- `02-pseudo-states.tcss`: pseudo-state feature set such as `:focus`, `:checked`, `:on`, `:open`, and `:selected`.
- `03-combinators.tcss`: child and descendant selector feature set.
- `04-big.tcss`: absurdly large sizing requests for layout stress testing.
- `05-small.tcss`: tiny sizing requests for clipping and minimum-size edge cases.
- `06-that70sShow.tcss`: intentionally obnoxious bright-color flexibility demo. Never do this, but it is good to know you can.

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
- Drag the blue divider to resize the frozen demo and stylesheet panel.
- Mouse and keyboard behavior outside the right panel continues to route to the frozen baseline demo.

## Current Scope

The harness currently switches and displays stylesheet source. The parser exists as `TCSSParser`, but the harness does not yet display diagnostics or apply parsed declarations to controls. TCSS files are feature-set tests and should eventually apply to all matching controls. `01-current-target.tcss` is the exception: it is the rolling scratch file for the isolated controls we are targeting in the current implementation step.

## Test Checklist

- `swiftual-tss-demo` builds as a separate executable.
- Right-side panel renders without changing `swiftual-demo`.
- Selector renders available stylesheet file names.
- Switching the selector updates the source preview.
- Switching a stylesheet logs the selected file.
- Baseline demo controls still render and handle events.
