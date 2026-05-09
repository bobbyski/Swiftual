# Tree

`Tree` displays expandable hierarchical rows in a fixed terminal-cell frame. It supports selection, expand/collapse, activation, clipping, and automatic vertical scrolling to keep the selected row visible.

## Creation

```swift
var tree = Tree(
    frame: Rect(x: 100, y: 8, width: 30, height: 7),
    roots: [
        TreeNode("Swiftual", children: [
            TreeNode("Controls", children: [
                TreeNode("Button"),
                TreeNode("DataTable"),
                TreeNode("Tree")
            ]),
            TreeNode("Runtime", isExpanded: false, children: [
                TreeNode("Terminal"),
                TreeNode("Events")
            ])
        ])
    ]
)
```

## Options

- `frame`: terminal-cell rectangle where the tree renders.
- `roots`: top-level `TreeNode` values.
- `selectedPath`: selected node path, such as `[0, 1, 0]`.
- `scrollOffset`: first visible tree row.
- `isFocused`: whether keyboard navigation applies.
- `fillStyle`: style used to fill the tree frame.
- `rowStyle`: normal row style.
- `selectedStyle`: selected row style when unfocused.
- `focusedSelectedStyle`: selected row style when focused.
- `scrollbarStyle`: style used for the two-column scrollbar track when visible rows overflow.
- `thumbStyle`: style used for the scrollbar thumb.
- `TreeNode.title`: displayed node text.
- `TreeNode.children`: child nodes.
- `TreeNode.isExpanded`: whether children are visible.

## Keyboard Behavior

- Down moves to the next visible row.
- Up moves to the previous visible row.
- Right expands the selected node when it has hidden children.
- Left collapses the selected expanded node; if it is already collapsed or has no children, Left moves selection to the parent.
- Enter or Space toggles expandable nodes, or activates leaf nodes.

## Mouse Behavior

- Clicking inside the tree focuses it.
- Clicking a visible row selects it.
- Clicking in the marker/indent area of an expandable row toggles expansion.
- Mouse wheel scrolls the tree when the pointer is inside the tree frame.
- Left click or drag on the two-column scrollbar moves the scroll offset proportionally.

## Rendering Behavior

- Expanded branch nodes show `v`.
- Collapsed branch nodes show `>`.
- Leaf nodes show `-`.
- Child rows indent by two cells per depth.
- Rows beyond the frame height are clipped.
- A two-column scrollbar appears when visible rows exceed the frame height.
- Tree text is clipped to leave space for the scrollbar when it appears.
- The selected row uses focused or unfocused selection styling.

## Demo Coverage

The demo renders a Swiftual feature tree on the right side of the screen. Press Tab until the tree is focused, use Up/Down to move, Left/Right to collapse or expand, and Enter or Space to toggle or activate. Mouse clicks select and toggle rows. The rich log records selected, expanded, collapsed, and activated nodes.

## Test Checklist

- Expanded rows render children.
- Collapsed rows hide children.
- Branch and leaf markers render.
- Selected row uses the focused selection style.
- Keyboard Up/Down changes selection.
- Keyboard Left/Right collapses and expands nodes.
- Enter and Space toggle expandable nodes or activate leaves.
- Mouse click selects rows.
- Mouse click on the marker area toggles rows.
- Mouse wheel scrolls overflowing tree content.
- Mouse drag on the scrollbar updates the scroll offset.
- Scrollbar appears only when visible rows overflow.
- Main view routes keyboard events to the tree.
- Main view routes mouse events to the tree.
- Demo renders the tree example.
- Rich log records tree selection, expansion, collapse, and activation.
