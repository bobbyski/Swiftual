# Switch

`Switch` is a compact one-line on/off toggle control.

## Creation

```swift
var toggle = Switch(
    "Power",
    frame: Rect(x: 68, y: 6, width: 14, height: 1),
    isOn: true
)
```

## Options

- `title`: label shown after the switch marker.
- `frame`: terminal-cell rectangle where the switch renders and receives mouse hits.
- `isOn`: current boolean state.
- `isFocused`: whether keyboard activation should apply.
- `isEnabled`: whether the switch can toggle.
- `offStyle`: style used for the off state.
- `onStyle`: style used for the on state.
- `focusedOffStyle`: style used when focused and off.
- `focusedOnStyle`: style used when focused and on.
- `disabledStyle`: style used when disabled.

## Rendering Behavior

- Off state renders as `<OFF> Title`.
- On state renders as `<ON> Title`.
- Text is clipped to the frame width.
- Focused off state uses the focused-off style across the whole frame.
- Focused on state keeps the green on-state background while adding bold focus styling.
- Disabled state uses the disabled style and ignores activation.

## Keyboard Behavior

- Space toggles a focused enabled switch.
- Enter toggles a focused enabled switch.
- Keyboard events are ignored when the switch is unfocused or disabled.

## Mouse Behavior

- Left click inside the frame focuses and toggles an enabled switch.
- Clicks outside the frame are ignored.

## Demo Coverage

The demo renders an enabled `Power` switch after the checkbox. Press Tab until it is focused, then use Space or Enter to toggle it. You can also click it with the mouse.

## Test Checklist

- Off switch renders `<OFF>`.
- On switch renders `<ON>`.
- Space toggles a focused switch.
- Enter toggles a focused switch.
- Unfocused keyboard input does not toggle.
- Disabled switch does not toggle.
- Mouse click inside the frame focuses and toggles.
- Focused on switch keeps the on-state color.
- Focused off switch uses the focused-off color.
- Demo renders the switch example.
- Main view can focus and toggle the switch through keyboard routing.
- Main view can focus and toggle the switch through mouse routing.
