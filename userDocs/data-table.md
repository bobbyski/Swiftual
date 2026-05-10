# Data Table

`DataTable` displays tabular rows in a fixed terminal-cell frame. It supports a header row, clipped cells, alternating row styles, selection, activation, and automatic vertical scrolling to keep the selected row visible.

## Creation

```swift
var table = DataTable(
    frame: Rect(x: 74, y: 8, width: 24, height: 5),
    columns: [
        DataTableColumn("Feature", width: 12),
        DataTableColumn("State", width: 10)
    ],
    rows: [
        ["Menu", "Ready"],
        ["Button", "Ready"],
        ["Modal", "Ready"],
        ["Log", "Ready"],
        ["Table", "New"]
    ]
)
```

## Options

- `frame`: terminal-cell rectangle where the table renders.
- `columns`: ordered `DataTableColumn` definitions.
- `rows`: row data. Missing cells render as empty text.
- `selectedRowIndex`: current selected row.
- `scrollOffset`: first visible row below the header.
- `isFocused`: whether keyboard navigation applies.
- `headerStyle`: style used for the header row.
- `rowStyle`: style used for even rows.
- `alternateRowStyle`: style used for odd rows.
- `selectedRowStyle`: style used for selection while unfocused.
- `focusedSelectedRowStyle`: style used for selection while focused.

## Keyboard Behavior

- Down moves selection down one row when focused.
- Up moves selection up one row when focused.
- Enter or Space activates the selected row when focused.
- Selection clamps at the first and last rows.
- `scrollOffset` updates to keep the selected row visible.

## Mouse Behavior

- Clicking inside the table focuses it.
- Clicking a visible row selects that row.
- Clicking the header focuses the table without changing selection.

## Rendering Behavior

- The first row is always the header.
- Visible body rows render below the header.
- Cells are clipped to their column widths.
- Column separators render between columns using the same background as the row or header they bisect.
- Rows beyond the available body height are clipped.
- Selection uses the focused or unfocused selection style.

## Future Grid Presentation

The current table should remain the default compact terminal table: header, body rows, and column separators only. A future optional presentation mode should support Rich-style full grid drawing for tables that need a stronger framed look.

This is a DataTable rendering option, not the same thing as the layout `Grid` container. It should reuse Swiftual's border character vocabulary where possible, including single, double, dashed, rounded, and ASCII drawing sets.

Possible future options:

- Minimal separators, the current default.
- Column separators only.
- Outer border only.
- Header rule plus column separators.
- Full grid with row and column rules.
- Selectable grid character set.

Grid line backgrounds should continue matching the row, header, or selected row they bisect so styled tables do not show mismatched vertical or horizontal seams.

## Demo Coverage

The demo renders a compact feature/status table in the upper-right area. Press Tab until the table is focused, use Up/Down to move selection, and press Enter or Space to activate the selected row. Mouse clicks select visible rows. The rich log records selected and activated rows, including the row index and cell values.

## Test Checklist

- Header row renders.
- Body rows render below the header.
- Column separators render.
- Column separator backgrounds match the current row or header.
- Future optional full-grid mode renders with selectable box-drawing styles without becoming the default.
- Selected row uses selection style.
- Keyboard Up/Down changes selection.
- Enter and Space activate the selected row.
- Mouse click selects a visible row.
- Selection scrolling keeps the selected row visible.
- Main view routes keyboard events to the table.
- Main view routes mouse events to the table.
- Demo renders the table example.
- Rich log records selected and activated rows.
