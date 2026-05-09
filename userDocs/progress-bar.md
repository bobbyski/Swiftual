# Progress Bar

`ProgressBar` renders progress in a fixed terminal-cell frame. It can show determinate completion with a filled track, or an indeterminate pulse when the current value is unknown.

## Creation

```swift
let progressBar = ProgressBar(
    frame: Rect(x: 52, y: 18, width: 20, height: 1),
    value: 0.65,
    label: "Load"
)
```

Use `value: nil` for indeterminate progress:

```swift
let progressBar = ProgressBar(
    frame: Rect(x: 2, y: 1, width: 30, height: 1),
    value: nil,
    pulseOffset: tick
)
```

## Options

- `frame`: terminal-cell rectangle where the bar renders.
- `value`: current determinate value, or `nil` for indeterminate mode.
- `range`: lower and upper bounds for determinate values. Defaults to `0...1`.
- `label`: optional text rendered with the percentage.
- `showPercentage`: whether determinate progress includes a percentage.
- `pulseOffset`: animation position for indeterminate progress.
- `trackStyle`: style used for the unfilled bar.
- `completedStyle`: style used for completed progress.
- `pulseStyle`: style used for the indeterminate pulse.
- `textStyle`: style used for centered text.

## Keyboard Behavior

`ProgressBar` is display-only and does not handle keyboard input.

## Mouse Behavior

`ProgressBar` is display-only and does not handle mouse input.

## Rendering Behavior

- Determinate values clamp to the configured range.
- Completed width is proportional to `fractionComplete`.
- Indeterminate mode renders a moving pulse inside the frame.
- Optional text is centered on the middle row of the frame.
- Text is clipped to the frame width.
- One-row-high progress bars are supported.

## Demo Coverage

The demo renders a one-row progress bar labeled `Load` next to the modal launcher. It shows `65%` completion.

## Test Checklist

- Determinate progress fills the expected number of cells.
- Values below and above the range clamp to `0` and `1`.
- Label and percentage render centered in the frame.
- Indeterminate progress renders a pulse at `pulseOffset`.
- Demo renders the progress bar example.
