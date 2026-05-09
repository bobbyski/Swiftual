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

`swiftual-tss-demo` now applies selected TCSS files to:

- `Screen`, through the base demo background style.
- `MenuBar`, through the menu bar's Swift style properties.
- `Menu`, through the popup menu style.
- `MenuItem`, through selected and disabled menu item styles.

This means selecting `06-that70sShow.tcss` should visibly change the live demo background, menu bar, and open File dropdown colors, not only the source preview.

## Test Checklist

- Type, class, ID, and pseudo-state selectors match contexts.
- Higher specificity beats lower specificity.
- Later source order wins when specificity ties.
- Switching TCSS files in the demo applies live `Screen`, `MenuBar`, `Menu`, and `MenuItem` styles.
- Switching back to baseline resets demo styles instead of retaining values from the previous stylesheet.
