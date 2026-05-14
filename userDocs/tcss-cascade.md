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
- `typeNames`: optional additional type aliases for Textual-style base-type matching. `typeName` is always included automatically.
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

Type aliases let custom or future subclass-like controls match shared selectors without losing their primary Swiftual type:

```swift
let customButton = TCSSStyleContext(typeName: "ToolbarButton", typeNames: ["Button"])
```

## Variables

Top-level variables may be declared as `$name: value;` before or between rules, then used in declaration values:

```css
$accent: bright-cyan;

Button.primary {
    background: $accent;
}
```

Variables resolve before declarations are converted into typed Swiftual style values. They do not participate in selector matching.

## Important Declarations

Declaration values may end with `!important`:

```css
Button {
    background: green !important;
}
```

Importance is tracked per property. An important `background` declaration does not make the same rule's `color` declaration important unless `color` also has its own marker. Important declarations beat normal declarations before specificity and source order are considered.

## Current Scope

The cascade currently supports:

- Type selectors: `MenuBar`
- Type aliases: `ToolbarButton` may also advertise `Button`.
- Universal selectors: `*`
- Class selectors: `Label.centered`
- ID selectors: `Button#primary`
- Pseudo-state selectors: `Button:focus`
- Grouped selectors through the parser/model pipeline.
- Direct child selectors: `MenuBar > Menu`
- Descendant selectors: `ScrollView ScrollBarThumb`

It resolves conflicts by declaration importance first, then specificity, then source order. Specificity is compared as a tuple in the CSS/Textual order: IDs, then classes and pseudo-states, then type names. That means `#primary` still beats `.a.b.c.d`, regardless of how many classes are chained together.

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
- Type selectors may match the context's primary type name or any advertised type alias.
- Universal selectors match any context with zero specificity.
- Child selectors require a direct parent in `TCSSStyleContext.ancestors`.
- Descendant selectors match any later ancestor in `TCSSStyleContext.ancestors`.
- Important declarations beat normal declarations per property.
- Higher specificity beats lower specificity using ID/class/type tuple ordering.
- Later source order wins when specificity ties.
- Switching TCSS files in the demo applies live styles across all current demo controls.
- Switching back to baseline resets demo styles through `TCSSStyleLayer` instead of retaining values from the previous stylesheet.
