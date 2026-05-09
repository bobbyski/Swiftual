# Testing

Swiftual features should be testable without a real terminal. The current tests use a virtual `TerminalDevice` and direct control rendering.

## Current Strategy

- Render controls into `Canvas`.
- Assert cell characters and styles.
- Simulate keyboard events by calling `handle(_:)`.
- Simulate mouse events with zero-based `MouseEvent` coordinates.
- Render through `ANSITerminalBackend` into a virtual device.
- Assert emitted ANSI output for important terminal behavior.

## Virtual Terminal Pattern

```swift
private final class VirtualTerminalDevice: TerminalDevice, @unchecked Sendable {
    var output = ""
    private let terminalSize: TerminalSize

    init(size: TerminalSize) {
        self.terminalSize = size
    }

    func readInput(maxBytes: Int) throws -> [UInt8] { [] }
    func writeOutput(_ output: String) throws { self.output += output }
    func size() -> TerminalSize { terminalSize }
    func enableRawMode() throws {}
    func restoreMode() {}
}
```

## Feature Doc As Test Plan

Each page in `userDocs` includes a test checklist. When a feature is implemented or changed, the checklist should be used to decide:

- Which unit tests to add.
- Which integration tests to add.
- Which demo behavior should be manually checked.
- Which edge cases need explicit documentation.

## Test Checklist

- Each implemented feature has a user doc page.
- Each user doc page has a test checklist.
- Each checked feature in the plan has matching tests.
- Protocol-backed terminal behavior can be tested with a virtual device.

