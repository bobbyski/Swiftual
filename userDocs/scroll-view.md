# Scroll View

`ScrollView` displays a clipped vertical viewport over a list of text rows.

## Creation

```swift
let scrollView = ScrollView(
    frame: Rect(x: 74, y: 14, width: 24, height: 5),
    content: (1...12).map { "Scroll row \($0)" }
)
```

## Options

- `frame`: terminal-cell rectangle where the viewport renders.
- `content`: ordered text rows.
- `contentHeight`: number of content rows.
- `scrollOffset`: first visible row index.
- `isFocused`: whether keyboard scrolling should apply.
- `fillStyle`: style used to fill the viewport.
- `scrollbarStyle`: style used for the scrollbar track.
- `thumbStyle`: style used for the scrollbar thumb.
- `contentStyle`: style used for content text.
- `scrollbarWidth`: scrollbar width in terminal cells, defaulting to `2`. Set it to `1` when a compact scrollbar is preferred.

## Keyboard Behavior

- Down scrolls down one row when focused.
- Up scrolls up one row when focused.
- Scrolling clamps at the top and bottom.

## Mouse Behavior

- Mouse wheel down scrolls down one row when inside the frame.
- Mouse wheel up scrolls up one row when inside the frame.
- Left click inside the frame focuses the scroll view.
- Left click or drag on either scrollbar column moves the scroll offset proportionally.

## Rendering Behavior

- Content rows are clipped to the viewport height.
- Content text is clipped to leave room for the scrollbar when content overflows.
- A two-column scrollbar appears by default when `contentHeight > frame.height`.
- A one-column scrollbar is available by setting `scrollbarWidth` to `1`.
- The scrollbar thumb size is proportional to visible rows.
- The scrollbar thumb position is proportional to `scrollOffset`.

## Demo Coverage

The demo renders a scroll view containing twelve rows. Press Tab until it is focused, then use Up/Down. You can also use the mouse wheel inside the scroll view.

## Test Checklist

- Visible rows render from `scrollOffset`.
- Rows outside the viewport are clipped.
- Keyboard Up/Down scrolls when focused.
- Mouse wheel scrolls when inside the frame.
- Mouse drag on the scrollbar thumb/track updates the scroll offset.
- Scroll offset clamps at top and bottom.
- Scrollbar appears only when content overflows.
- Demo renders the scroll view example.
- Main view can focus and scroll through keyboard routing.
- Main view can focus and scroll through mouse routing.
