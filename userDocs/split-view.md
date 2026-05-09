# Split View

Split views divide a region into two resizable panes. They are pure Swift controls and do not require TCSS.

## HorizontalSplitView

`HorizontalSplitView` creates left and right panes separated by a vertical divider.

```swift
var split = HorizontalSplitView(
    frame: Rect(x: 0, y: 1, width: 120, height: 30),
    dividerOffset: 80,
    minLeading: 30,
    minTrailing: 20
)
```

Use `leadingFrame`, `dividerFrame`, and `trailingFrame` to place child content. The split view renders the divider and handles divider dragging.

## VerticalSplitView

`VerticalSplitView` creates top and bottom panes separated by a horizontal divider.

```swift
var split = VerticalSplitView(
    frame: Rect(x: 0, y: 1, width: 120, height: 30),
    dividerOffset: 12,
    minTop: 4,
    minBottom: 4
)
```

Use `topFrame`, `dividerFrame`, and `bottomFrame` to place child content.

## Options

- `frame`: outer region controlled by the split view.
- `dividerOffset`: current divider position from the leading edge or top edge.
- `dividerWidth` / `dividerHeight`: divider thickness. Defaults to `1`. Demos may override this to `2` for easier mouse targeting.
- `minLeading` / `minTrailing`: minimum left and right pane sizes for horizontal splits.
- `minTop` / `minBottom`: minimum top and bottom pane sizes for vertical splits.
- `isClamped`: when `true`, divider movement honors minimum pane sizes. When `false`, the divider may move to the outer bounds of the split view while still staying inside the split frame.
- `dividerStyle`: terminal style used to draw the divider.
- `isDragging`: active drag state, normally managed by `handle(_:)`.

## Mouse Behavior

- Press the left mouse button on the divider to focus the split.
- Drag while pressed to resize panes.
- Release the mouse button to end the drag.
- Divider movement is clamped so neither pane can shrink below its configured minimum.
- If `isClamped` is `false`, dragging ignores minimum pane sizes and only clamps to the split view bounds.

## Keyboard Behavior

Keyboard resizing is not implemented yet. Future keyboard support should use focused split controls and arrow-key resizing.

## Test Checklist

- Horizontal split computes left, divider, and right frames.
- Vertical split computes top, divider, and bottom frames.
- Divider rendering uses the configured style.
- Dragging resizes the divider.
- Dragging clamps against minimum pane sizes.
- Unclamped mode allows the divider to reach the split bounds.
- The TCSS demo uses `HorizontalSplitView` for its draggable source panel divider.
- The main demo uses `VerticalSplitView` for its fixed bottom rich-log pane.
