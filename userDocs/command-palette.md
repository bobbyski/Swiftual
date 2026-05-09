# Command Palette

`CommandPalette` displays a modal command picker over the current terminal view. It supports filtering, keyboard selection, mouse selection, dismissal, and command activation without requiring TCSS.

## Creation

```swift
var palette = CommandPalette(
    frame: Rect(x: 38, y: 5, width: 44, height: 10),
    items: [
        CommandPaletteItem("Quit", detail: "Exit the demo"),
        CommandPaletteItem("Show modal", detail: "Open the modal overlay"),
        CommandPaletteItem("Start worker", detail: "Run async progress"),
        CommandPaletteItem("Cancel worker", detail: "Stop async progress"),
        CommandPaletteItem("Focus tree", detail: "Move focus to tree")
    ]
)

palette.present()
```

## Options

- `frame`: terminal-cell rectangle for the palette panel.
- `title`: title rendered in the top row.
- `items`: command rows to display.
- `query`: current filter text.
- `highlightedIndex`: highlighted row within the filtered result set.
- `isPresented`: whether the palette is visible.
- `panelStyle`: background style for the panel.
- `titleStyle`: style for the title row.
- `inputStyle`: style for the filter field.
- `itemStyle`: style for normal command rows.
- `highlightedStyle`: style for the highlighted command row.
- `disabledStyle`: style for disabled rows and empty results.

## Keyboard Behavior

- Ctrl-P opens the demo command palette from the main view.
- Printable characters update the query.
- Backspace removes the previous query character.
- Down and Tab move the highlight down.
- Up moves the highlight up.
- Enter selects the highlighted enabled command.
- Escape dismisses the palette.

## Mouse Behavior

- Clicking the demo `Commands` button opens the palette.
- Clicking a visible command row selects it.
- Clicking outside the palette dismisses it.

## Rendering Behavior

- The title row uses the title style.
- The query row is rendered as `> query`.
- The command list filters by title or detail using case-insensitive contains matching.
- The highlighted row uses focused styling.
- Empty results show `No matches`.
- The palette overlays the current screen without clearing it.

## Demo Coverage

The demo includes a `Commands` button near the tree. Use Ctrl-P or click `Commands`, type a filter such as `f`, and press Enter to focus the tree. The rich log records palette open, query, highlight, dismissal, and selection events.

## Test Checklist

- Palette filters command items by title.
- Palette filters command items by detail.
- Keyboard Enter selects the highlighted command.
- Escape dismisses the palette.
- Mouse click selects visible rows.
- Ctrl-P opens the command palette in the main view.
- Main view applies command selections such as focusing the tree.
- Demo renders the command palette launcher.
- Rich log records command palette interaction.
