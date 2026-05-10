# Swiftual User Docs

Swiftual is a Swift terminal UI framework. These docs are written as the project grows: each feature page describes the public behavior, options, keyboard and mouse expectations, and the test cases that should keep that behavior stable.

## Current Package Layout

- Framework source lives in `Code/Swiftual/Sources/Swiftual`.
- Framework docs and deferred issue notes live in `Code/Swiftual/userDocs` and `Code/Swiftual/issues`.
- The pure Swift demo app lives in `Code/SwiftualDemo/Sources/SwiftualDemo`.
- The TCSS demo app lives in `Code/SwiftualTCSSDemo/Sources/SwiftualTCSSDemo`.
- RichSwift is a sibling package at `Code/RichSwift`; Swiftual references it as a dependency rather than including its source.

## Current Feature Docs

- [Terminal Backends](terminal-backends.md)
- [Main View Container](main-view-container.md) demo-only harness
- [Menu Bar](menu-bar.md)
- [Menu](menu.md)
- [Menu Item](menu-item.md)
- [Button](button.md)
- [Label And Static Text](label.md)
- [Vertical Container](vertical.md)
- [Horizontal Container](horizontal.md)
- [Flow Layout](flow-layout.md)
- [Split View](split-view.md)
- [Text Input](text-input.md)
- [Checkbox](checkbox.md)
- [Switch](switch.md)
- [Select](select.md)
- [Scroll View](scroll-view.md)
- [Modal Screen](modal.md)
- [Progress Bar](progress-bar.md)
- [Rich Log](rich-log.md)
- [Data Table](data-table.md)
- [Tree](tree.md)
- [Command Palette](command-palette.md)
- [Worker-Backed Async Task Demo](workers.md)
- [TCSS Demo Harness](tcss-demo.md) demo-only harness
- [TCSS Parser](tcss-parser.md)
- [TCSS Style Model](tcss-style-model.md)
- [TCSS Cascade](tcss-cascade.md)
- [Input Events](input-events.md)
- [Styling](styling.md)
- [Canvas And Rendering](canvas-rendering.md)
- [Testing](testing.md)

## Planned Feature Docs

These pages should be added as each feature lands:

- Remaining TCSS control application
- Textual-inspired demo duplicates

## Documentation Rule

Every new control or framework capability should update this documentation set in the same change that implements the feature. The page should include:

- What the feature does.
- How to create it in pure Swift.
- Supported options and defaults.
- Keyboard behavior.
- Mouse behavior.
- Rendering and styling expectations.
- Test checklist.
