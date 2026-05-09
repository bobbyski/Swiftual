# Worker-Backed Async Tasks

`WorkerManager` owns cancellable Swift structured-concurrency tasks and publishes `WorkerEvent` values that the app can drain during its normal update loop. The demo uses it to run a background progress task and log progress without blocking terminal input.

## Creation

```swift
let workers = WorkerManager()

workers.startDemoTask(steps: 10, interval: .milliseconds(250))

for event in workers.drainEvents() {
    log.append(event.message)
}
```

## Options

- `WorkerState.idle`: no active task.
- `WorkerState.running`: task is active.
- `WorkerState.completed`: task finished successfully.
- `WorkerState.cancelled`: task was cancelled.
- `WorkerState.failed(String)`: reserved state for failed worker reporting.
- `WorkerEvent.state`: state at the time of the event.
- `WorkerEvent.progress`: clamped `0...1` progress value.
- `WorkerEvent.message`: human-readable log text.
- `startDemoTask(steps:interval:)`: starts a cancellable progress task.
- `cancel()`: cooperatively cancels the active task.
- `drainEvents()`: returns pending events and clears the queue.

## Keyboard Behavior

- Tab can focus the demo worker button.
- Enter or Space starts the worker when idle.
- Enter or Space cancels the worker while it is running.

## Mouse Behavior

- Clicking `Run worker` starts the async task.
- Clicking the same button while running cancels it.

## Rendering Behavior

- The demo renders a worker button and a determinate progress bar.
- Idle workers render at 0%.
- Running workers advance as events are drained by the app loop.
- Completion renders 100% and logs a completion event.
- Cancellation logs a cancellation event.

## Demo Coverage

The demo places `Run worker` near the command palette button and tree. Starting the worker logs `Worker started.`, then progress events, then `Worker completed.`. While running, the button changes to `Cancel job`.

## Test Checklist

- Worker starts in the running state.
- Worker publishes a start event.
- Worker publishes progress events.
- Worker publishes a completion event.
- Worker cancellation publishes a cancellation event.
- Main view can start the worker with the mouse.
- Demo renders the worker launcher and progress bar.
- Rich log receives drained worker events.
