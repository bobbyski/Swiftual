import Foundation

public struct TCSSStyleContext: Equatable, Sendable {
    public var typeName: String
    public var id: String?
    public var classNames: Set<String>
    public var pseudoStates: Set<String>

    public init(
        typeName: String,
        id: String? = nil,
        classNames: Set<String> = [],
        pseudoStates: Set<String> = []
    ) {
        self.typeName = typeName
        self.id = id
        self.classNames = classNames
        self.pseudoStates = pseudoStates
    }
}

public struct TCSSCascade: Sendable {
    public var model: TCSSStyleModel

    public init(model: TCSSStyleModel) {
        self.model = model
    }

    public func style(for context: TCSSStyleContext) -> TCSSStyle {
        var resolved = TCSSStyle()
        var winningTerminal = TCSSPropertyWeights()
        var winningLayout = TCSSPropertyWeights()

        for (ruleIndex, rule) in model.rules.enumerated() {
            for selector in rule.selectors {
                guard selector.matches(context) else { continue }
                let weight = TCSSCascadeWeight(specificity: selector.specificity, sourceOrder: ruleIndex)
                resolved.merge(rule.style, weight: weight, terminalWeights: &winningTerminal, layoutWeights: &winningLayout)
            }
        }

        return resolved
    }
}

private struct TCSSCascadeWeight: Comparable {
    var specificity: Int
    var sourceOrder: Int

    static func < (lhs: TCSSCascadeWeight, rhs: TCSSCascadeWeight) -> Bool {
        if lhs.specificity != rhs.specificity {
            return lhs.specificity < rhs.specificity
        }
        return lhs.sourceOrder < rhs.sourceOrder
    }
}

private struct TCSSPropertyWeights {
    var foreground: TCSSCascadeWeight?
    var background: TCSSCascadeWeight?
    var bold: TCSSCascadeWeight?
    var inverse: TCSSCascadeWeight?
    var width: TCSSCascadeWeight?
    var height: TCSSCascadeWeight?
    var minWidth: TCSSCascadeWeight?
    var minHeight: TCSSCascadeWeight?
    var maxWidth: TCSSCascadeWeight?
    var maxHeight: TCSSCascadeWeight?
    var padding: TCSSCascadeWeight?
    var margin: TCSSCascadeWeight?
    var textAlign: TCSSCascadeWeight?
    var dividerWidth: TCSSCascadeWeight?
    var dividerHeight: TCSSCascadeWeight?
}

private extension TCSSSelector {
    var specificity: Int {
        segments.reduce(0) { partial, segment in
            partial
                + (segment.id == nil ? 0 : 100)
                + (segment.classNames.count * 10)
                + (segment.pseudoStates.count * 10)
                + (segment.typeName == nil ? 0 : 1)
        }
    }

    func matches(_ context: TCSSStyleContext) -> Bool {
        guard segments.count == 1, let segment = segments.first else { return false }
        return segment.matches(context)
    }
}

private extension TCSSSelectorSegment {
    func matches(_ context: TCSSStyleContext) -> Bool {
        if let typeName, typeName != context.typeName {
            return false
        }
        if let id, id != context.id {
            return false
        }
        if !Set(classNames).isSubset(of: context.classNames) {
            return false
        }
        if !Set(pseudoStates).isSubset(of: context.pseudoStates) {
            return false
        }
        return true
    }
}

private extension TCSSStyle {
    mutating func merge(
        _ incoming: TCSSStyle,
        weight: TCSSCascadeWeight,
        terminalWeights: inout TCSSPropertyWeights,
        layoutWeights: inout TCSSPropertyWeights
    ) {
        assign(incoming.terminalStyle.foreground, to: \.terminalStyle.foreground, weight: weight, winning: &terminalWeights.foreground)
        assign(incoming.terminalStyle.background, to: \.terminalStyle.background, weight: weight, winning: &terminalWeights.background)
        assign(incoming.terminalStyle.bold, to: \.terminalStyle.bold, weight: weight, winning: &terminalWeights.bold)
        assign(incoming.terminalStyle.inverse, to: \.terminalStyle.inverse, weight: weight, winning: &terminalWeights.inverse)
        assign(incoming.layout.width, to: \.layout.width, weight: weight, winning: &layoutWeights.width)
        assign(incoming.layout.height, to: \.layout.height, weight: weight, winning: &layoutWeights.height)
        assign(incoming.layout.minWidth, to: \.layout.minWidth, weight: weight, winning: &layoutWeights.minWidth)
        assign(incoming.layout.minHeight, to: \.layout.minHeight, weight: weight, winning: &layoutWeights.minHeight)
        assign(incoming.layout.maxWidth, to: \.layout.maxWidth, weight: weight, winning: &layoutWeights.maxWidth)
        assign(incoming.layout.maxHeight, to: \.layout.maxHeight, weight: weight, winning: &layoutWeights.maxHeight)
        assign(incoming.layout.padding, to: \.layout.padding, weight: weight, winning: &layoutWeights.padding)
        assign(incoming.layout.margin, to: \.layout.margin, weight: weight, winning: &layoutWeights.margin)
        assign(incoming.layout.textAlign, to: \.layout.textAlign, weight: weight, winning: &layoutWeights.textAlign)
        assign(incoming.layout.dividerWidth, to: \.layout.dividerWidth, weight: weight, winning: &layoutWeights.dividerWidth)
        assign(incoming.layout.dividerHeight, to: \.layout.dividerHeight, weight: weight, winning: &layoutWeights.dividerHeight)
    }

    mutating func assign<Value>(
        _ value: Value?,
        to keyPath: WritableKeyPath<TCSSStyle, Value?>,
        weight: TCSSCascadeWeight,
        winning: inout TCSSCascadeWeight?
    ) {
        guard let value else { return }
        if let winning, winning > weight {
            return
        }
        self[keyPath: keyPath] = value
        winning = weight
    }
}
