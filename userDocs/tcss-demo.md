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
- The right panel starts below the blue menu bar.
- A selector at the top chooses a sample stylesheet.
- A scrollable source preview below shows the selected stylesheet text.
- The panel is intentionally separate so stylesheet parsing and per-control application can be tested one control at a time.

## Included Stylesheets

- `00-baseline.tcss`: captures the frozen Swift styling.
- `01-buttons-labels.tcss`: first target for Button and Label selectors.
- `02-inputs-choice.tcss`: target for TextInput, Checkbox, Switch, and Select.
- `03-data-navigation.tcss`: target for DataTable, Tree, ScrollView, and RichLog.

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
- Mouse and keyboard behavior outside the right panel continues to route to the frozen baseline demo.

## Current Scope

The harness currently switches and displays stylesheet source. It does not yet parse or apply TCSS declarations to controls. That implementation is tracked in the plan as an indented per-control checklist under the optional TCSS layer.

## Test Checklist

- `swiftual-tss-demo` builds as a separate executable.
- Right-side panel renders without changing `swiftual-demo`.
- Selector renders available stylesheet file names.
- Switching the selector updates the source preview.
- Switching a stylesheet logs the selected file.
- Baseline demo controls still render and handle events.
