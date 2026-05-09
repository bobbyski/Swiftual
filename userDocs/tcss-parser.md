# TCSS Parser

`TCSSParser` parses optional Swiftual stylesheet text into a structured `TCSSStylesheet`. It does not apply styles yet; it provides the syntax model and diagnostics that the style model and cascade steps will consume.

## Creation

```swift
let stylesheet = TCSSParser().parse("""
Button:focus,
Label.centered {
    background: blue;
    color: bright-white;
}
""")
```

## Parsed Model

- `TCSSStylesheet.rules`: parsed style rules.
- `TCSSStylesheet.diagnostics`: non-fatal parser diagnostics.
- `TCSSRule.selectors`: one or more selectors split from comma-separated selector lists.
- `TCSSRule.declarations`: property/value declarations in the block.
- `TCSSSelector.raw`: original selector text.
- `TCSSSelector.segments`: selector path split into type/class/id/pseudo-state segments.
- `TCSSSelectorSegment.typeName`: widget or element type name such as `Button`.
- `TCSSSelectorSegment.id`: `#id` selector value.
- `TCSSSelectorSegment.classNames`: `.class` selector values.
- `TCSSSelectorSegment.pseudoStates`: `:focus`, `:checked`, `:open`, and other pseudo-state values.
- `TCSSSelectorSegment.combinator`: `.none`, `.descendant`, or `.child`.
- `TCSSDeclaration.property`: declaration property name.
- `TCSSDeclaration.value`: raw declaration value.
- `TCSSDeclaration.line`: 1-based source line.
- `TCSSDiagnostic.line`: 1-based source line for a parser issue.
- `TCSSDiagnostic.message`: human-readable diagnostic text.

## Supported Syntax

- Block comments: `/* comment */`
- Type selectors: `Button`
- Class selectors: `Label.centered`
- ID selectors: `Button#primary`
- Pseudo-states: `Button:focus`, `Checkbox:checked`, `Switch:on`
- Grouped selectors: `Checkbox:checked, Switch:on`
- Child combinator: `DataTable > Header`
- Descendant combinator: `ScrollView ScrollBarThumb`
- Declaration blocks: `property: value;`

## Diagnostics

The parser keeps going after recoverable errors. It reports:

- Missing `{` after a selector.
- Unexpected `}` without a matching block.
- Unclosed declaration block.
- Empty selectors in a selector list.
- Declarations missing `:`.
- Declarations missing a property name.
- Declarations missing a value.

## Current Scope

The parser stores declaration values as raw strings. Converting `background: blue` into a `TerminalStyle`, validating supported properties, computing specificity, and applying style rules are tracked as later TCSS checklist items.

## Test Checklist

- Comments are ignored while preserving line numbers.
- Grouped selectors produce multiple selectors.
- Pseudo-states parse into selector segments.
- Class and ID selector pieces parse into selector segments.
- Child and descendant combinators are preserved.
- Declarations preserve property names, values, and source lines.
- Malformed blocks produce diagnostics without crashing.
