# Flow Layout

Swiftual flow layout arranges renderable children in terminal-cell space without each demo or app computing every child coordinate by hand.

The first implementation covers the Textual-equivalent pieces: vertical flow, horizontal flow, grouped containers, scrollable flow containers, grid placement, alignment, fixed sizing, percentage sizing, fractional sizing, auto sizing, optional fill styles, and optional border titles.

`Absolute`, `Window`, and `StatusBar` are intentionally left for a later design pass.

## Creation

```swift
let flow = FlowContainer(
    frame: Rect(x: 2, y: 2, width: 40, height: 10),
    axis: .vertical,
    spacing: FlowSpacing(main: 1),
    padding: BoxEdges(1),
    alignment: .topLeading,
    fillStyle: TerminalStyle(foreground: .brightWhite, background: .black),
    border: .single(),
    borderTitle: "Settings",
    children: [
        FlowChild(Label("Name", frame: Rect(x: 0, y: 0, width: 10, height: 1))),
        FlowChild(Button("Save", frame: Rect(x: 0, y: 0, width: 12, height: 1)))
    ]
)
```

Convenience containers are available for common Textual-style layouts:

```swift
let stack = Vertical(frame: frame, border: .single(), borderTitle: "Vertical", children: children)
let row = Horizontal(frame: frame, border: .single(), borderTitle: "Horizontal", children: children)
let group = VerticalGroup(frame: frame, children: flowChildren)
let scroller = VerticalScroll(frame: frame, scrollOffset: 2, children: flowChildren)
let grid = Grid(frame: frame, columns: 2, gutter: 1, borderTitle: "Grid", children: flowChildren)
```

Textual's border label pattern is supported directly:

```swift
let panel = FlowContainer(
    frame: frame,
    axis: .vertical,
    border: .single(titleAlignment: .center, subtitleAlignment: .right),
    borderTitle: "Filters",
    borderSubtitle: "Ready",
    children: flowChildren
)
```

Border character sets use real Unicode box-drawing characters by default:

```swift
FlowBorder.single()  // ┌ ┐ └ ┘ ─ │
FlowBorder.double()  // ╔ ╗ ╚ ╝ ═ ║
FlowBorder.dashed()  // ┌ ┐ └ ┘ ╌ ╎
FlowBorder.rounded() // ╭ ╮ ╰ ╯ ─ │
FlowBorder.ascii()   // + + + + - |
```

## Options

- `axis`: `.vertical` stacks top to bottom; `.horizontal` places left to right.
- `spacing`: fixed cells between children on the main axis.
- `padding`: inset applied inside the border and before child layout.
- `alignment`: cross-axis placement such as leading, centered, right/bottom, or stretch.
- `overflow`: visible, hidden, scroll, or auto policy values for each axis.
- `scrollOffset`: viewport offset used by scrollable flow containers.
- `fillStyle`: optional style used to fill the full container frame.
- `border`: optional border style.
- `borderTitle`: optional title rendered into the top border.
- `borderSubtitle`: optional subtitle rendered into the bottom border.
- `children`: `FlowChild` values wrapping any `CanvasRenderable`.

## Border Titles

Swiftual follows Textual's border label shape:

- `borderTitle` maps to Textual's `border_title` and renders in the top border.
- `borderSubtitle` maps to Textual's `border_subtitle` and renders in the bottom border.
- Title alignment defaults to `.left`.
- Subtitle alignment defaults to `.right`.
- `.left`, `.center`, and `.right` alignment are supported.
- Title and subtitle styles are independent through `FlowBorder.titleStyle` and `FlowBorder.subtitleStyle`.
- Empty titles and subtitles are not displayed.
- Border labels are only rendered when the border is visible.
- Single-line Unicode box drawing is the default border character set.
- Double-line, dashed, rounded, and ASCII border character sets are available through `FlowBorder`.

## Sizing

Each `FlowChild` can carry `LayoutPreferences`:

- `.cells(n)`: exact terminal-cell length.
- `.percent(p)`: percentage of available parent space.
- `.fraction(n)`: share of remaining main-axis space.
- `.containerWidth(p)` / `.containerHeight(p)`: Textual-style `w` and `h` scalar units resolved against the container dimensions.
- `.viewportWidth(p)` / `.viewportHeight(p)`: Textual-style `vw` and `vh` scalar units resolved against an explicit viewport size when available, falling back to the current container frame.
- `.auto`: use the child renderable's current frame as intrinsic size.
- `.fill`: consume the available cross axis or remaining main-axis space.

Minimum and maximum width/height constraints clamp the resolved frame.

## Rendering Behavior

- Containers render fill first, then border, then children.
- Borders reserve one cell on each side.
- Hidden, scroll, and auto overflow clip children to the content frame.
- Visible overflow lets children render past the container frame until the canvas edge.
- `Vertical` and `Horizontal` preserve their existing public initializers and now delegate placement to `FlowContainer`.
- The demo labels its vertical and horizontal examples with border titles.

## Test Checklist

- Vertical flow stacks children and preserves spacing.
- Horizontal flow places children left to right and preserves spacing.
- Fractional children split remaining space proportionally.
- Percent and auto sizing resolve to stable integer cell frames.
- Border and border titles render around content.
- Border subtitles render in the bottom border with Textual-style default right alignment.
- Single, double, dashed, rounded, and ASCII border character sets render the expected edge and corner glyphs.
- Scrollable vertical flow respects `scrollOffset`.
- Grid places children in multiple columns with gutters.
- The demo renders titled bordered examples for vertical and horizontal containers.
