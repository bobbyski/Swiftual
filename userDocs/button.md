# Button

`Button` is a clickable and keyboard-activatable control.

## Creation

```swift
var button = Button(
    "Quit",
    frame: Rect(x: 2, y: 6, width: 12, height: 1)
) {
    // action
}
```

## Options

- `title`: text shown inside the button.
- `frame`: terminal-cell rectangle where the button renders and receives mouse hits.
- `isFocused`: whether keyboard activation should apply.
- `isEnabled`: whether the button can activate.
- `action`: closure invoked on activation. Defaults to a no-op closure.

## One-Row Buttons

Swiftual must support one-row-high buttons as a first-class layout. This is an intentional improvement over Textual behavior where one-high buttons are not as clean as desired.

One-row buttons should:

- Center the title horizontally as well as the width allows.
- Render focused state clearly.
- Activate with keyboard when focused.
- Activate with mouse when clicked inside the frame.
- Avoid requiring extra vertical padding.

## Keyboard Behavior

- Enter activates a focused enabled button.
- Space activates a focused enabled button.
- Keyboard events are ignored when the button is not focused.

## Mouse Behavior

- Left click inside the button frame activates an enabled button.
- Clicks outside the frame are ignored.

## Styling

Current default styling:

- Normal: black text on bright white background.
- Focused: bright white text on blue background, bold.
- Disabled: white text on bright black background.

## Demo Coverage

The demo renders three showcase buttons:

- `Normal`: default enabled button style.
- `Focused`: focused one-row button style.
- `Disabled`: disabled one-row button style.

These examples are intentionally visible at the same time so style differences can be checked manually and through canvas tests.

## Test Checklist

- Focused one-row button renders with blue background and bold text.
- Enter activates a focused button.
- Enter does not activate an unfocused button.
- Mouse click inside the button frame activates it.
- Mouse click outside the frame does not activate it.
- Disabled button does not activate.
- Demo renders normal, focused, and disabled button examples.
