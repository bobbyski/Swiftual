# Modal Screen

`Modal` displays a temporary screen over the current canvas. It is useful for confirmation prompts, short messages, and focused choices that should capture input until dismissed.

## Creation

```swift
var modal = Modal(
    frame: Rect(x: 24, y: 8, width: 36, height: 8),
    title: "Swiftual",
    message: "Modal screen example",
    buttons: [
        ModalButton("OK"),
        ModalButton("Cancel")
    ]
)
```

Call `present()` to show the modal and `dismiss()` to hide it.

## Options

- `frame`: terminal-cell rectangle for the modal panel.
- `title`: text rendered in the top title row.
- `message`: short message rendered in the panel body.
- `buttons`: ordered action buttons.
- `selectedButtonIndex`: currently focused button.
- `isPresented`: whether the modal renders and handles input.
- `overlayStyle`: full-screen style behind the panel.
- `panelStyle`: modal body style.
- `titleStyle`: title row style.
- `buttonStyle`: normal button style.
- `focusedButtonStyle`: selected button style.
- `disabledButtonStyle`: disabled button style.

## Keyboard Behavior

- Escape dismisses the modal.
- Left moves to the previous enabled button.
- Right or Tab moves to the next enabled button.
- Enter or Space activates the selected enabled button and dismisses the modal.

## Mouse Behavior

- Clicking an enabled button activates it and dismisses the modal.
- Clicking outside the modal frame dismisses the modal.
- Mouse input inside the panel but outside buttons is ignored.

## Rendering Behavior

- The overlay fills the full canvas while the modal is presented.
- The panel fills `frame` using `panelStyle`.
- The title row uses `titleStyle` and centers the title within the frame.
- The message is clipped to the inner panel width.
- Buttons render on one terminal row near the bottom of the modal.

## Demo Coverage

The demo includes a `Show modal` button in the main view. Press Tab until the button is focused, then press Enter or Space to present the modal. Use Left/Right/Tab to move between buttons, Enter to select, or Escape to dismiss.

## Test Checklist

- Modal renders only when `isPresented` is true.
- Overlay, title row, message, and buttons render with the expected styles.
- Escape dismisses the modal.
- Keyboard navigation changes the selected button.
- Enter and Space select the focused enabled button.
- Disabled buttons are skipped by keyboard navigation and cannot be activated.
- Mouse click on a button selects it.
- Mouse click outside the modal dismisses it.
- Main view routes input to a presented modal before other controls.
- Demo renders the modal launcher button.
