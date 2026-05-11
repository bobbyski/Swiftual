# DataTable Rich-Style Border Fidelity Issue

Status: Open. This is a nice-to-have polish issue, not a blocker for the current control set.

## Summary

`DataTable` now supports multiple presentation modes, including compact tables, framed tables, and full grids. The framed/grid work is good enough for demo coverage, but it does not yet perfectly match Rich's table border construction.

The desired look is the Rich-style table shown in Bobby's reference output:

```text
┏━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Name                  ┃ Directory                                                              ┃ Status                                         ┃
┡━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│ addiebasic            │ /Users/bobby/src/AddieBasic/addiebasic                                 │ up to date on feature/basic_package            │
```

Key details:

- The outer frame can use heavy or double-like characters.
- The top border has intersections between columns.
- The header separator uses a different construction from the top/bottom border.
- Header vertical rules may be visually distinct from body vertical rules.
- Body rows do not necessarily need horizontal separators between every row.
- The visual vocabulary should eventually align with Rich/SwiftRich table border styles rather than inventing a separate Swiftual-only grammar.

## Expected Behavior

`DataTablePresentation.framed(...)` should support a Rich-style framed table:

- Top border: corner + horizontal rule + column tees.
- Header row: vertical column rules.
- Header separator: left tee + horizontal rule + column crossings + right tee.
- Body rows: vertical column rules, usually no horizontal separator between each body row.
- Bottom border: corner + horizontal rule + column tees.
- Line character choice should be selectable: single, heavy, double, rounded, dashed, ASCII, and ideally Rich-compatible presets if SwiftRich exposes them.

`DataTablePresentation.grid(...)` can remain the busier mode with row separators between body rows.

## Current Behavior

The current implementation is functional enough for the demo, but the border model is too simple:

- `DataTableGridCharacters` has one set of top/header/bottom separators.
- It does not distinguish heavy top borders, mixed header separators, and light body rules in the Rich way.
- `.framed(...)` and `.grid(...)` share most of the same character vocabulary, so Rich-style table themes are hard to express precisely.

## Suspect Area 1: Character Model

File: `Code/Swiftual/Sources/Swiftual/DataTable.swift`

Types:

- `DataTableGridCharacters`
- `DataTableGridStyle`
- `DataTablePresentation`

Current shape:

```swift
public struct DataTableGridCharacters: Equatable, Sendable {
    public var topLeft: Character
    public var topSeparator: Character
    public var topRight: Character
    public var headerLeft: Character
    public var headerSeparator: Character
    public var headerRight: Character
    public var bottomLeft: Character
    public var bottomSeparator: Character
    public var bottomRight: Character
    public var horizontal: Character
    public var vertical: Character
}
```

Why this is suspect:

- Rich-style tables need more than one horizontal/vertical family.
- The header separator may use characters like `┡`, `╇`, and `┩` while the top border uses `┏`, `┳`, and `┓`.
- Body rows may use `│` while the header uses `┃`.
- A richer model probably needs named border parts for top/header/body/bottom rather than one shared `horizontal` and one shared `vertical`.

## Suspect Area 2: Framed Rendering

File: `Code/Swiftual/Sources/Swiftual/DataTable.swift`

Function: `renderFramed(_:in:)`

Current block:

```swift
private func renderFramed(_ gridStyle: DataTableGridStyle, in canvas: inout Canvas) {
    canvas.fill(rect: frame, style: rowStyle)
    renderGridRule(
        left: gridStyle.characters.topLeft,
        separator: gridStyle.characters.topSeparator,
        right: gridStyle.characters.topRight,
        horizontal: gridStyle.characters.horizontal,
        y: frame.y,
        style: rowStyle,
        in: &canvas
    )
    renderGridCells(columns.map(\.title), y: frame.y + 1, style: headerStyle, characters: gridStyle.characters, in: &canvas)
    renderGridRule(
        left: gridStyle.characters.headerLeft,
        separator: gridStyle.characters.headerSeparator,
        right: gridStyle.characters.headerRight,
        horizontal: gridStyle.characters.horizontal,
        y: frame.y + 2,
        style: headerStyle,
        in: &canvas
    )

    let visibleHeight = visibleRowCapacity
    for offset in 0..<visibleHeight {
        let rowIndex = scrollOffset + offset
        guard rows.indices.contains(rowIndex) else { break }
        renderGridRow(rows[rowIndex], rowIndex: rowIndex, y: frame.y + 3 + offset, characters: gridStyle.characters, in: &canvas)
    }

    renderGridRule(
        left: gridStyle.characters.bottomLeft,
        separator: gridStyle.characters.bottomSeparator,
        right: gridStyle.characters.bottomRight,
        horizontal: gridStyle.characters.horizontal,
        y: frame.y + frame.height - 1,
        style: rowStyle,
        in: &canvas
    )
}
```

Why this is suspect:

- `renderFramed` currently gets closer to the intended shape, but it still cannot express a Rich-style mixed border set.
- It delegates body/header cell drawing to `renderGridCells`, which always uses the same vertical character for every row type.
- It should eventually render header cells and body cells with separate vertical characters if the selected border preset requires that.

## Suspect Area 3: Rule Rendering Helper

File: `Code/Swiftual/Sources/Swiftual/DataTable.swift`

Function: `renderGridRule(left:separator:right:horizontal:y:style:in:)`

Current block:

```swift
private func renderGridRule(
    left: Character,
    separator: Character,
    right: Character,
    horizontal: Character,
    y: Int,
    style: TerminalStyle,
    in canvas: inout Canvas
) {
    guard y >= frame.y, y < frame.y + frame.height else { return }
    var x = frame.x
    guard x < frame.x + frame.width else { return }
    canvas.drawText(String(left), at: Point(x: x, y: y), style: style)
    x += 1
    for columnIndex in columns.indices {
        let width = min(columns[columnIndex].width, max(0, frame.x + frame.width - x - 1))
        guard width > 0 else { return }
        canvas.drawText(String(repeating: String(horizontal), count: width), at: Point(x: x, y: y), style: style)
        x += width
        guard x < frame.x + frame.width else { return }
        let character = columnIndex == columns.count - 1 ? right : separator
        canvas.drawText(String(character), at: Point(x: x, y: y), style: style)
        x += 1
    }
}
```

Why this is suspect:

- This helper assumes every horizontal segment in a rule uses one repeated character.
- That is probably fine, but the caller needs a richer rule description: top rule, header separator rule, body separator rule, bottom rule.
- If we adopt Rich-compatible presets, this helper may become `renderTableRule(_ rule: DataTableRuleCharacters, ...)`.

## Proposed Later Fix

1. Introduce a richer border character model, possibly:

   ```swift
   public struct DataTableBorderCharacters {
       public var top: DataTableRuleCharacters
       public var headerSeparator: DataTableRuleCharacters
       public var rowSeparator: DataTableRuleCharacters?
       public var bottom: DataTableRuleCharacters
       public var headerVertical: Character
       public var bodyVertical: Character
   }
   ```

2. Add Rich-compatible presets:

   - `richHeavy`
   - `richSimple`
   - `richDouble`
   - `single`
   - `double`
   - `rounded`
   - `ascii`

3. Update `.framed(...)` to use:

   - top rule
   - header verticals
   - header separator rule
   - body verticals
   - bottom rule

4. Keep `.grid(...)` as the mode that draws row separators between every body row.

5. Add tests for:

   - top column intersections
   - header separator intersections
   - distinct header/body vertical characters
   - no body row separators in framed mode
   - optional body row separators in grid mode

## Priority

Low. This would make tables prettier and more Rich-compatible, but the current DataTable rendering is usable and should not block TCSS, flow layout, or control coverage.
