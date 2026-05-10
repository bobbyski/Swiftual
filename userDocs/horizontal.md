# Horizontal Container

`Horizontal` places child renderables from left to right inside a fixed terminal-cell frame. It is now backed by `FlowContainer(axis: .horizontal)`, so it shares the same flow sizing and border behavior as the general layout system.

## Creation

```swift
let horizontal = Horizontal(
    frame: Rect(x: 36, y: 14, width: 36, height: 3),
    spacing: 2,
    fillStyle: TerminalStyle(foreground: .brightWhite, background: .black),
    border: .single(),
    borderTitle: "Horizontal",
    borderSubtitle: "Ready",
    children: [
        AnyCanvasRenderable(Label("Horizontal", frame: Rect(x: 0, y: 0, width: 12, height: 1))),
        AnyCanvasRenderable(Button("One", frame: Rect(x: 0, y: 0, width: 8, height: 1))),
        AnyCanvasRenderable(Button("Two", frame: Rect(x: 0, y: 0, width: 8, height: 1), isFocused: true))
    ]
)
```

## Options

- `frame`: terminal-cell rectangle where the container renders.
- `spacing`: number of blank columns between children. Defaults to `0`.
- `fillStyle`: optional style used to fill the container before children render.
- `border`: optional border drawn around the container.
- `borderTitle`: optional title rendered into the top border.
- `borderSubtitle`: optional subtitle rendered into the bottom border.
- `children`: ordered child renderables.

## Child Placement

Children are placed at the content area's `y` coordinate and the next available `x` coordinate. Child frames provide their intrinsic width and height, but their final position is controlled by the horizontal flow container.

The current implementation uses:

- Container `y` for every child.
- Running `x` based on previous child width plus spacing.
- Child width clipped to remaining container width.
- Child height clipped to container height.

## Rendering Behavior

- The container can optionally fill its own frame before children render.
- The container can optionally render a border and border title.
- Border title and subtitle alignment follow the same Textual-style defaults as `FlowContainer`.
- Children render in array order.
- Children that would start beyond the right edge are skipped.
- Children that partially fit are clipped to remaining width.

## Demo Coverage

The demo renders a horizontal stack with:

- A label.
- A normal one-row button.
- A focused one-row button.
- A border title labeling the container type.

## Test Checklist

- Children lay out left to right.
- `spacing` inserts columns between children.
- Optional fill style is applied across the container frame.
- Children are clipped to the container width.
- Child height is clipped to the container height.
- Demo renders a visible horizontal stack section.
