# Menu Bar

`MenuBar` displays top-level menus across the first terminal row.

## Creation

```swift
let menuBar = MenuBar(
    menus: [
        Menu("File", items: [
            MenuItem("Quit", shortcut: "Q") {}
        ])
    ]
)
```

## Styling

Current default styling:

- Menu bar: white text on blue background.
- Focused top-level menu: white text on blue background.
- Open top-level menu: blue text on bright white background.

This is intentional: top-level menus should match the menu bar until clicked or opened.

`MenuBar` also exposes pure Swift style properties:

- `barStyle`
- `selectedBarStyle`
- `menuStyle`
- `selectedItemStyle`
- `disabledItemStyle`

The optional TCSS demo can apply `MenuBar` rules to `barStyle` and `selectedBarStyle`; pure Swift styling remains the default API.

## Keyboard Behavior

- Left arrow: moves to the previous top-level menu.
- Right arrow: moves to the next top-level menu.
- Tab: moves to the next top-level menu while menu bar owns focus.
- Down arrow: opens the selected menu or moves down inside an open menu.
- Up arrow: opens the selected menu from the bottom or moves up inside an open menu.
- Enter/Space: opens the selected menu or activates the selected item.
- Escape: closes the open menu.
- `q` and Ctrl-C currently request quit in the demo.

## Mouse Behavior

- Click a top-level menu title to open that menu.
- Click a menu item inside the open popup to activate it.
- Click outside the open menu to close it.

## Test Checklist

- Focused but closed menu uses the menu bar style.
- Open menu title uses the active/open style.
- Down arrow opens the menu.
- Enter activates the selected item.
- Mouse click on the title opens the menu.
- Mouse click on an item activates it.
