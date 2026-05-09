# Menu

`Menu` represents one top-level menu and its menu items.

## Creation

```swift
Menu("File", items: [
    MenuItem("Quit", shortcut: "Q") {}
])
```

## Popup Rendering

When opened, a menu renders as a popup starting on the row below the menu bar. Its width is calculated from item titles and shortcut text, with a minimum width of 12 cells.

## Selection

The menu bar tracks:

- `openedMenuIndex`
- `selectedItemIndex`

The first enabled item is selected when the menu opens from the top. The last enabled item is selected when opening upward.

## Styling

Current default styling:

- Normal item: black text on bright black background.
- Selected item: bright white text on blue background.
- Disabled item: white text on bright black background.

## Test Checklist

- Popup appears below the selected top-level menu.
- First enabled item is selected when opening with Down.
- Last enabled item is selected when opening with Up.
- Disabled items cannot activate.
- Selection wraps when moving beyond the first or last item.

