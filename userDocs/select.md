# Select

`Select` is a compact dropdown-style menu list control.

## Creation

```swift
var select = Select(
    frame: Rect(x: 84, y: 6, width: 14, height: 1),
    options: [
        SelectOption("Alpha"),
        SelectOption("Beta"),
        SelectOption("Gamma")
    ]
)
```

## Options

- `frame`: terminal-cell rectangle where the closed select renders.
- `options`: ordered list of `SelectOption` values.
- `selectedIndex`: currently selected option index.
- `highlightedIndex`: currently highlighted option index while open.
- `isOpen`: whether the option popup is visible.
- `isFocused`: whether keyboard activation should apply.
- `isEnabled`: whether the select can open or change.
- `style`: normal closed style.
- `focusedStyle`: focused closed style.
- `openStyle`: style for the closed row while the popup is open.
- `optionStyle`: normal option row style.
- `highlightedStyle`: highlighted option row style.
- `disabledStyle`: disabled select/option style.

## Select Options

```swift
SelectOption("Beta", isEnabled: false)
```

Disabled options are visible but skipped by keyboard navigation and cannot be selected.

## Keyboard Behavior

- Space or Enter opens a focused closed select.
- Space or Enter selects the highlighted option when open.
- Down opens the select when closed.
- Down moves highlight to the next enabled option when open.
- Up opens the select when closed.
- Up moves highlight to the previous enabled option when open.
- Escape closes without changing selection.

## Mouse Behavior

- Left click on the closed row focuses and opens the select.
- Left click an option selects it.
- Left click outside closes the popup when open.

## Rendering Behavior

- Closed state renders selected title followed by `v`.
- Open state renders option rows below the closed row.
- Highlighted option uses highlighted style.
- Option rows are clipped by the available canvas height.

## Demo Coverage

The demo renders a select after the switch with `Alpha`, `Beta`, and `Gamma` options. Press Tab until it is focused, then use Down/Up and Enter. You can also click the closed row and then click an option.

## Test Checklist

- Closed select renders selected option.
- Open select renders option rows.
- Down opens the select and moves highlight.
- Up opens the select and moves highlight.
- Enter selects the highlighted option.
- Escape closes without changing selection.
- Disabled options are skipped by keyboard navigation.
- Mouse can open and select an option.
- Demo renders the select example.
- Main view can use the select through keyboard routing.
- Main view can use the select through mouse routing.

