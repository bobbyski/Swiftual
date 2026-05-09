# Menu Item

`MenuItem` is an actionable row inside a `Menu`.

## Creation

```swift
MenuItem("Quit", shortcut: "Q") {
    // action
}
```

## Options

- `title`: visible menu item title.
- `shortcut`: optional shortcut label displayed at the right side of the item.
- `isEnabled`: controls whether the item can be selected and activated.
- `action`: closure invoked when the item activates.

## Activation

A menu item activates when:

- It is enabled.
- It is selected.
- The user presses Enter or Space, or clicks its row with the mouse.

In the current demo, an item titled `Quit` also returns a `.quit` command to the app loop.

## Test Checklist

- Enabled items can activate.
- Disabled items do not activate.
- Shortcut text appears in the rendered row.
- The `Quit` item exits the demo.

