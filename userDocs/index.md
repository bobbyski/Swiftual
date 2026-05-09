# Swiftual User Docs

Swiftual is a Swift terminal UI framework. These docs are written as the project grows: each feature page describes the public behavior, options, keyboard and mouse expectations, and the test cases that should keep that behavior stable.

## Current Feature Docs

- [Terminal Backends](terminal-backends.md)
- [Main View Container](main-view-container.md)
- [Menu Bar](menu-bar.md)
- [Menu](menu.md)
- [Menu Item](menu-item.md)
- [Button](button.md)
- [Label And Static Text](label.md)
- [Vertical Container](vertical.md)
- [Input Events](input-events.md)
- [Styling](styling.md)
- [Canvas And Rendering](canvas-rendering.md)
- [Testing](testing.md)

## Planned Feature Docs

These pages should be added as each feature lands:

- Horizontal container
- Text input
- Checkbox
- Switch
- Select/menu list
- Scroll view
- Modal screen
- Progress bar
- Log/Rich log
- Data table
- Tree
- Command palette
- Worker-backed async task demo

## Documentation Rule

Every new control or framework capability should update this documentation set in the same change that implements the feature. The page should include:

- What the feature does.
- How to create it in pure Swift.
- Supported options and defaults.
- Keyboard behavior.
- Mouse behavior.
- Rendering and styling expectations.
- Test checklist.
