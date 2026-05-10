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

## Current Scope

The cascade currently supports single-segment selectors:

- Type selectors: `MenuBar`
- Class selectors: `Label.centered`
- ID selectors: `Button#primary`
- Pseudo-state selectors: `Button:focus`
- Grouped selectors through the parser/model pipeline.

It resolves conflicts by specificity first, then source order.

Descendant and child combinators are parsed but are not matched by the cascade yet.

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
- Higher specificity beats lower specificity.
- Later source order wins when specificity ties.
- Switching TCSS files in the demo applies live styles across all current demo controls.
- Switching back to baseline resets demo styles instead of retaining values from the previous stylesheet.
