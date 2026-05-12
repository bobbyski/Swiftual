# TCSS Cascade

`TCSSCascade` resolves a `TCSSStyleModel` for a specific control context. It is the bridge between parsed style data and live control styling.

## Creation

```swift
let model = TCSSStyleModelBuilder().parse(source)
let cascade = TCSSCascade(model: model)

let style = cascade.style(
    for: TCSSStyleContext(
        typeName: "MenuBar",
        pseudoStates: []
    )
)
```

## Context

`TCSSStyleContext` describes the control being styled:

- `typeName`: control type such as `Screen`, `MenuBar`, or `Button`.
- `id`: optional `#id` selector value.
- `classNames`: class names available to `.class` selectors.
- `pseudoStates`: active pseudo-states such as `focus`, `checked`, or `open`.
- `ancestors`: nearest-parent-first `TCSSStyleContextNode` values for child and descendant selector matching.

You can build a child context from a parent:

```swift
let menuBar = TCSSStyleContextNode(typeName: "MenuBar")
let menu = TCSSStyleContext(typeName: "Menu", ancestors: [menuBar])
```

Or use `child(...)` when walking a hierarchy:

```swift
let menu = TCSSStyleContext(typeName: "MenuBar").child(typeName: "Menu")
```

## Current Scope

The cascade currently supports:

- Type selectors: `MenuBar`
- Class selectors: `Label.centered`
- ID selectors: `Button#primary`
- Pseudo-state selectors: `Button:focus`
- Grouped selectors through the parser/model pipeline.
- Direct child selectors: `MenuBar > Menu`
- Descendant selectors: `ScrollView ScrollBarThumb`

It resolves conflicts by specificity first, then source order.

## Current Demo Application

`swiftual-tcss-demo` now applies selected TCSS files to:

- `Screen`, through the base demo background style.
- `MenuBar`, through the menu bar's Swift style properties.
- `Menu`, through the popup menu style.
- `MenuItem`, through selected and disabled menu item styles.
- `Button`, `Button:focus`, and `Button:disabled`, including width and height.
- `Label` plus the demo classes `Label.left`, `Label.centered`, and `Label.right`, including `text-align`.
- `Vertical` and `Horizontal`, through their demo fill and child styles.
- `TextInput`, `TextInput:focus`, `Placeholder`, and `Cursor`.
- `Checkbox`, `Checkbox:focus`, `Checkbox:checked`, and `Checkbox:disabled`.
- `Switch`, `Switch:on`, `Switch:focus`, and `Switch:disabled`.
- `Select`, `Select:focus`, `Select:open`, `Option`, `Option:selected`, and `Option:disabled`.
- `ScrollView`, `ScrollContent`, `ScrollBar`, and `ScrollBarThumb`.
- `Modal`, `ModalOverlay`, `ModalTitle`, `ModalButton`, `ModalButton:focus`, and `ModalButton:disabled`.
- `ProgressBar`, `ProgressBar:complete`, `ProgressBar:pulse`, and `ProgressBarText`.
- `RichLog` and `RichLogTitle`.
- `DataTable`, `Header`, `Row`, `Row:alternate`, `Row:selected`, and `Row:focus:selected`.
- `Tree`, `Tree:selected`, `Tree:focus:selected`, and `TreeBranch`.
- `CommandPalette`, `CommandPaletteTitle`, `CommandPaletteInput`, `CommandPaletteItem`, `CommandPaletteItem:selected`, and `CommandPaletteItem:disabled`.
- `WorkerProgress`, `WorkerProgress:complete`, and `WorkerProgressText`.

This means selecting `06-that70sShow.tcss` should visibly change the live demo background, menus, controls, content surfaces, scrollbars, progress bars, and overlay surfaces, not only the source preview.

## Test Checklist

- Type, class, ID, and pseudo-state selectors match contexts.
- Child selectors require a direct parent in `TCSSStyleContext.ancestors`.
- Descendant selectors match any later ancestor in `TCSSStyleContext.ancestors`.
- Higher specificity beats lower specificity.
- Later source order wins when specificity ties.
- Switching TCSS files in the demo applies live styles across all current demo controls.
- Switching back to baseline resets demo styles through `TCSSStyleLayer` instead of retaining values from the previous stylesheet.
