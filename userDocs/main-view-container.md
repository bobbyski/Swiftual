# Main View Container

`MainViewContainer` is the current root container for the demo. It owns the menu bar, a grey full-screen body, and the first button control.

## Behavior

The container renders:

- A blue menu bar at the top row.
- A grey body filling the remaining terminal area.
- Demo text in the body.
- A one-row `Quit` button.

## Focus

The current focus enum is:

```swift
public enum MainViewFocus {
    case menuBar
    case button
}
```

`Tab` moves focus between the menu bar and the button when the menu is not open.

## Input Routing

- Menu bar focus sends events to `MenuBar`.
- Button focus sends events to `Button`.
- A mouse click inside the button frame focuses and activates the button.
- A mouse click outside the button can return routing to the menu bar.

## Test Checklist

- The body fills all rows below the menu bar with the configured background.
- The menu bar renders over the body on row zero.
- `Tab` can move focus to the button.
- `Enter` on the focused button activates it.
- Mouse click inside the button frame activates it.

