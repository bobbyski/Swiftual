# Checkbox

`Checkbox` is a one-line toggle control with checked and unchecked states.

## Creation

```swift
var checkbox = Checkbox(
    "Enable feature",
    frame: Rect(x: 46, y: 6, width: 20, height: 1),
    isChecked: true
)
```

## Options

- `title`: label shown after the checkbox marker.
- `frame`: terminal-cell rectangle where the checkbox renders and receives mouse hits.
- `isChecked`: current boolean state.
- `isFocused`: whether keyboard activation should apply.
- `isEnabled`: whether the checkbox can toggle.
- `style`: normal style.
- `focusedStyle`: style used when focused.
- `disabledStyle`: style used when disabled.

## Rendering Behavior

- Unchecked state renders as `[ ] Title`.
- Checked state renders as `[x] Title`.
- Text is clipped to the frame width.
- Focused state uses the focused style across the whole frame.
- Disabled state uses the disabled style and ignores activation.

## Keyboard Behavior

- Space toggles a focused enabled checkbox.
- Enter toggles a focused enabled checkbox.
- Keyboard events are ignored when the checkbox is unfocused or disabled.

## Mouse Behavior

- Left click inside the frame focuses and toggles an enabled checkbox.
- Clicks outside the frame are ignored.

## Demo Coverage

The demo renders a checked `Enable feature` checkbox next to the text input. Press Tab until it is focused, then use Space or Enter to toggle it. You can also click it with the mouse.

## Test Checklist

- Unchecked checkbox renders `[ ]`.
- Checked checkbox renders `[x]`.
- Space toggles a focused checkbox.
- Enter toggles a focused checkbox.
- Unfocused keyboard input does not toggle.
- Disabled checkbox does not toggle.
- Mouse click inside the frame focuses and toggles.
- Demo renders the checkbox example.
- Main view can focus and toggle the checkbox through keyboard routing.
- Main view can focus and toggle the checkbox through mouse routing.

