# Vertical Container

`Vertical` stacks child renderables from top to bottom inside a fixed terminal-cell frame. It is now backed by `FlowContainer(axis: .vertical)`, so it shares the same flow sizing and border behavior as the general layout system.

## Creation

```swift
let vertical = Vertical(
    frame: Rect(x: 2, y: 14, width: 30, height: 5),
    spacing: 1,
    fillStyle: TerminalStyle(foreground: .brightWhite, background: .black),
    border: .single(),
    borderTitle: "Vertical",
    borderSubtitle: "Ready",
    children: [
        AnyCanvasRenderable(Label("Header", frame: Rect(x: 0, y: 0, width: 30, height: 1))),
        AnyCanvasRenderable(Button("Run", frame: Rect(x: 0, y: 0, width: 12, height: 1)))
    ]
)
```

## Options

- `frame`: terminal-cell rectangle where the container renders.
- `spacing`: number of blank rows between children. Defaults to `0`.
- `fillStyle`: optional style used to fill the container before children render.
- `border`: optional border drawn around the container.
- `borderTitle`: optional title rendered into the top border.
- `borderSubtitle`: optional subtitle rendered into the bottom border.
- `children`: ordered child renderables.

## Child Placement

Children are placed at the content area's `x` coordinate and the next available `y` coordinate. Child frames provide their intrinsic width and height, but their final position is controlled by the vertical flow container.

The current implementation uses:

- Container `x` for every child.
- Running `y` based on previous child height plus spacing.
- Child width clipped to container width.
- Child height clipped to remaining container height.

## Rendering Behavior

- The container can optionally fill its own frame before children render.
- The container can optionally render a border and border title.
- Border title and subtitle alignment follow the same Textual-style defaults as `FlowContainer`.
- Children render in array order.
- Children that would start below the container are skipped.
- Children that partially fit are clipped to remaining height.

## Demo Coverage

The demo renders a vertical stack with:

- A centered label.
- A styled child label.
- A one-row child button.
- A border title labeling the container type.

## Test Checklist

- Children stack top to bottom.
- `spacing` inserts rows between children.
- Optional fill style is applied across the container frame.
- Children are clipped to the container height.
- Child width is clipped to the container width.
- Demo renders a visible vertical stack section.
