# Text Input

`TextInput` is a focused, single-line editable text control.

## Creation

```swift
var input = TextInput(
    text: "Swift",
    placeholder: "Type here",
    frame: Rect(x: 18, y: 6, width: 24, height: 1)
)
```

## Options

- `text`: current input value.
- `placeholder`: text shown when the input is empty and unfocused.
- `frame`: terminal-cell rectangle where the input renders and receives mouse hits.
- `cursorIndex`: insertion cursor index. Defaults to the end of `text`.
- `isFocused`: whether keyboard editing applies.
- `isEnabled`: whether the input can receive edits.
- `style`: normal style.
- `focusedStyle`: style used when focused.
- `placeholderStyle`: style used for placeholder text.
- `cursorStyle`: style used for the visible cursor cell.

## Keyboard Behavior

- Printable characters insert at the cursor.
- Backspace removes the character before the cursor.
- Left arrow moves the cursor left.
- Right arrow moves the cursor right.
- Enter submits the current text.
- Keyboard events are ignored when unfocused or disabled.

## Mouse Behavior

- Left click inside the frame focuses the input.
- Click position moves the cursor near the clicked column.
- Clicks outside the frame are ignored by the input.

## Rendering Behavior

- The input fills its frame with the normal or focused style.
- Text starts one cell inside the frame.
- Text is clipped to available content width.
- Focused text scrolls horizontally so the cursor remains visible as text grows beyond the frame.
- Placeholder text appears only when the input is empty and unfocused.
- Focused input renders a styled cursor cell.

## Demo Coverage

The demo renders a text input next to the Quit button. Press Tab twice to focus it, then type. You can also click inside the input to focus it.

## Test Checklist

- Empty unfocused input renders placeholder text.
- Focused input inserts printable characters.
- Backspace removes the character before the cursor.
- Left and right arrows move the cursor.
- Long text scrolls horizontally to keep the cursor visible.
- Moving the cursor left scrolls earlier text back into view.
- Enter submits the current text.
- Mouse click inside the frame focuses and positions the cursor.
- Demo renders the text input example.
- Main view can focus and edit the input through keyboard routing.
- Main view can focus the input through mouse routing.
