import Foundation

public enum WorkerState: Equatable, Sendable {
    case idle
    case running
    case completed
    case cancelled
    case failed(String)
}

public struct WorkerEvent: Equatable, Sendable {
    public var state: WorkerState
    public var progress: Double
    public var message: String

    public init(state: WorkerState, progress: Double, message: String) {
        self.state = state
        self.progress = min(1, max(0, progress))
        self.message = message
    }
}

public final class WorkerManager: @unchecked Sendable {
    private let lock = NSLock()
    private var task: Task<Void, Never>?
    private var queuedEvents: [WorkerEvent] = []

    public private(set) var state: WorkerState = .idle
    public private(set) var progress: Double = 0

    public init() {}

    deinit {
        task?.cancel()
    }

    public func startDemoTask(steps: Int = 10, interval: Duration = .milliseconds(250)) {
        cancel()
        record(WorkerEvent(state: .running, progress: 0, message: "Worker started."))
        let stepCount = max(1, steps)

        task = Task { [weak self] in
            for step in 1...stepCount {
                if Task.isCancelled {
                    self?.record(WorkerEvent(state: .cancelled, progress: self?.progressSnapshot() ?? 0, message: "Worker cancelled."))
                    return
                }
                do {
                    try await Task.sleep(for: interval)
                } catch {
                    self?.record(WorkerEvent(state: .cancelled, progress: self?.progressSnapshot() ?? 0, message: "Worker cancelled."))
                    return
                }
                self?.record(WorkerEvent(state: .running, progress: Double(step) / Double(stepCount), message: "Worker progress: \(step)/\(stepCount)."))
            }
            self?.record(WorkerEvent(state: .completed, progress: 1, message: "Worker completed."))
        }
    }

    public func cancel() {
        guard let task else { return }
        task.cancel()
        self.task = nil
        record(WorkerEvent(state: .cancelled, progress: progressSnapshot(), message: "Worker cancel requested."))
    }

    public func drainEvents() -> [WorkerEvent] {
        lock.lock()
        defer { lock.unlock() }
        let events = queuedEvents
        queuedEvents.removeAll()
        return events
    }

    private func record(_ event: WorkerEvent) {
        lock.lock()
        state = event.state
        progress = event.progress
        queuedEvents.append(event)
        if event.state != .running {
            task = nil
        }
        lock.unlock()
    }

    private func progressSnapshot() -> Double {
        lock.lock()
        defer { lock.unlock() }
        return progress
    }
}

extension WorkerManager: Equatable {
    public static func == (lhs: WorkerManager, rhs: WorkerManager) -> Bool {
        lhs.state == rhs.state && lhs.progress == rhs.progress
    }
}
