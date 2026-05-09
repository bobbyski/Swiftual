# Rich Log

`RichLog` displays styled log entries in a fixed terminal-cell frame. It is intended for event traces, status messages, and application diagnostics.

## Creation

```swift
var log = RichLog(
    frame: Rect(x: 2, y: 21, width: 96, height: 3),
    entries: [
        RichLogEntry("Ready")
    ]
)

log.append(
    "Modal picked option: Cancel.",
    style: TerminalStyle(foreground: .green, background: .black, bold: true)
)
```

## Options

- `frame`: terminal-cell rectangle where the log renders.
- `entries`: ordered log entries.
- `maxEntries`: maximum retained entries. Older entries are trimmed.
- `title`: title text rendered on the first row.
- `fillStyle`: style used for the log body.
- `titleStyle`: style used for the title row.
- `RichLogEntry.message`: message text.
- `RichLogEntry.style`: per-entry style.

## Keyboard Behavior

`RichLog` is display-only in this phase and does not handle keyboard input.

## Mouse Behavior

`RichLog` is display-only in this phase and does not handle mouse input.

## Rendering Behavior

- The title row renders at the top of the frame.
- Log entries render below the title.
- The newest entries are shown when there are more entries than visible rows.
- Entry text is clipped to the frame width.
- Entry backgrounds default to the log fill background when omitted.

## Demo Coverage

The demo renders a `Rich log` panel at the bottom of the screen. Interacting with controls appends messages:

- Menu opens and selections.
- Button activation.
- Text input focus, changes, cursor moves, and submission.
- Checkbox state changes.
- Switch state changes.
- Select opens, highlights, and picked options.
- Scroll view focus and scroll offsets.
- Modal open, highlight, dismiss, and selected option. Modal selections call out the exact option, such as `Modal picked option: Cancel.`
- Progress animation start and finish.

## Test Checklist

- Entries append in order.
- Entries trim to `maxEntries`.
- The title row renders.
- The latest visible entries render when content overflows.
- Per-entry styles render.
- Demo renders the rich log panel.
- Main view logs representative control actions.
- Main view logs the selected modal option by title.
