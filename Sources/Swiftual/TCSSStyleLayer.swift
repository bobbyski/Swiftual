import Foundation

public struct TCSSStyleLayer<Value: Sendable>: Sendable {
    public var defaultValue: Value
    public private(set) var value: Value

    public init(defaultValue: Value, value: Value? = nil) {
        self.defaultValue = defaultValue
        self.value = value ?? defaultValue
    }

    public mutating func reset() {
        value = defaultValue
    }

    public mutating func reset(to defaultValue: Value) {
        self.defaultValue = defaultValue
        value = defaultValue
    }

    public mutating func apply(_ body: (inout Value) -> Void) {
        body(&value)
    }

    public mutating func resetAndApply(_ body: (inout Value) -> Void) {
        reset()
        apply(body)
    }
}
