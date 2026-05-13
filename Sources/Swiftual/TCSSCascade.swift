import Foundation

public struct TCSSStyleContextNode: Equatable, Sendable {
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

public struct TCSSStyleContext: Equatable, Sendable {
    public var node: TCSSStyleContextNode
    public var ancestors: [TCSSStyleContextNode]

    public init(
        typeName: String,
        id: String? = nil,
        classNames: Set<String> = [],
        pseudoStates: Set<String> = [],
        ancestors: [TCSSStyleContextNode] = []
    ) {
        self.node = TCSSStyleContextNode(
            typeName: typeName,
            id: id,
            classNames: classNames,
            pseudoStates: pseudoStates
        )
        self.ancestors = ancestors
    }

    public init(node: TCSSStyleContextNode, ancestors: [TCSSStyleContextNode] = []) {
        self.node = node
        self.ancestors = ancestors
    }

    public var typeName: String {
        node.typeName
    }

    public var id: String? {
        node.id
    }

    public var classNames: Set<String> {
        node.classNames
    }

    public var pseudoStates: Set<String> {
        node.pseudoStates
    }

    public func child(
        typeName: String,
        id: String? = nil,
        classNames: Set<String> = [],
        pseudoStates: Set<String> = []
    ) -> TCSSStyleContext {
        TCSSStyleContext(
            typeName: typeName,
            id: id,
            classNames: classNames,
            pseudoStates: pseudoStates,
            ancestors: [node] + ancestors
        )
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
        var winningVisual = TCSSPropertyWeights()

        for (ruleIndex, rule) in model.rules.enumerated() {
            for selector in rule.selectors {
                guard selector.matches(context) else { continue }
                let weight = TCSSCascadeWeight(specificity: selector.specificity, sourceOrder: ruleIndex)
                resolved.merge(rule.style, weight: weight, terminalWeights: &winningTerminal, layoutWeights: &winningLayout, visualWeights: &winningVisual)
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
    var dim: TCSSCascadeWeight?
    var italic: TCSSCascadeWeight?
    var underline: TCSSCascadeWeight?
    var strikethrough: TCSSCascadeWeight?
    var inverse: TCSSCascadeWeight?
    var blink: TCSSCascadeWeight?
    var layoutKind: TCSSCascadeWeight?
    var dock: TCSSCascadeWeight?
    var align: TCSSCascadeWeight?
    var contentAlign: TCSSCascadeWeight?
    var layer: TCSSCascadeWeight?
    var layers: TCSSCascadeWeight?
    var width: TCSSCascadeWeight?
    var height: TCSSCascadeWeight?
    var widthLength: TCSSCascadeWeight?
    var heightLength: TCSSCascadeWeight?
    var minWidth: TCSSCascadeWeight?
    var minHeight: TCSSCascadeWeight?
    var maxWidth: TCSSCascadeWeight?
    var maxHeight: TCSSCascadeWeight?
    var padding: TCSSCascadeWeight?
    var margin: TCSSCascadeWeight?
    var textAlign: TCSSCascadeWeight?
    var overflow: TCSSCascadeWeight?
    var border: TCSSCascadeWeight?
    var position: TCSSCascadeWeight?
    var offset: TCSSCascadeWeight?
    var dividerWidth: TCSSCascadeWeight?
    var dividerHeight: TCSSCascadeWeight?
    var spacing: TCSSCascadeWeight?
    var opacity: TCSSCascadeWeight?
    var textOpacity: TCSSCascadeWeight?
    var display: TCSSCascadeWeight?
    var visibility: TCSSCascadeWeight?
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
        guard let last = segments.last, last.matches(context.node) else { return false }
        guard segments.count > 1 else { return true }

        var ancestorStart = 0
        for index in stride(from: segments.count - 1, through: 1, by: -1) {
            let relationship = segments[index].combinator
            let ancestorSegment = segments[index - 1]

            switch relationship {
            case .none:
                return false
            case .child:
                guard context.ancestors.indices.contains(ancestorStart),
                      ancestorSegment.matches(context.ancestors[ancestorStart])
                else {
                    return false
                }
                ancestorStart += 1
            case .descendant:
                guard let matchIndex = context.ancestors[ancestorStart...].firstIndex(where: { ancestorSegment.matches($0) }) else {
                    return false
                }
                ancestorStart = matchIndex + 1
            }
        }

        return true
    }
}

private extension TCSSSelectorSegment {
    func matches(_ context: TCSSStyleContextNode) -> Bool {
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
        layoutWeights: inout TCSSPropertyWeights,
        visualWeights: inout TCSSPropertyWeights
    ) {
        assign(incoming.terminalStyle.foreground, to: \.terminalStyle.foreground, weight: weight, winning: &terminalWeights.foreground)
        assign(incoming.terminalStyle.background, to: \.terminalStyle.background, weight: weight, winning: &terminalWeights.background)
        assign(incoming.terminalStyle.bold, to: \.terminalStyle.bold, weight: weight, winning: &terminalWeights.bold)
        assign(incoming.terminalStyle.dim, to: \.terminalStyle.dim, weight: weight, winning: &terminalWeights.dim)
        assign(incoming.terminalStyle.italic, to: \.terminalStyle.italic, weight: weight, winning: &terminalWeights.italic)
        assign(incoming.terminalStyle.underline, to: \.terminalStyle.underline, weight: weight, winning: &terminalWeights.underline)
        assign(incoming.terminalStyle.strikethrough, to: \.terminalStyle.strikethrough, weight: weight, winning: &terminalWeights.strikethrough)
        assign(incoming.terminalStyle.inverse, to: \.terminalStyle.inverse, weight: weight, winning: &terminalWeights.inverse)
        assign(incoming.terminalStyle.blink, to: \.terminalStyle.blink, weight: weight, winning: &terminalWeights.blink)
        assign(incoming.layout.layoutKind, to: \.layout.layoutKind, weight: weight, winning: &layoutWeights.layoutKind)
        assign(incoming.layout.dock, to: \.layout.dock, weight: weight, winning: &layoutWeights.dock)
        assign(incoming.layout.align, to: \.layout.align, weight: weight, winning: &layoutWeights.align)
        assign(incoming.layout.contentAlign, to: \.layout.contentAlign, weight: weight, winning: &layoutWeights.contentAlign)
        assign(incoming.layout.layer, to: \.layout.layer, weight: weight, winning: &layoutWeights.layer)
        assign(incoming.layout.layers, to: \.layout.layers, weight: weight, winning: &layoutWeights.layers)
        assign(incoming.layout.width, to: \.layout.width, weight: weight, winning: &layoutWeights.width)
        assign(incoming.layout.height, to: \.layout.height, weight: weight, winning: &layoutWeights.height)
        assign(incoming.layout.widthLength, to: \.layout.widthLength, weight: weight, winning: &layoutWeights.widthLength)
        assign(incoming.layout.heightLength, to: \.layout.heightLength, weight: weight, winning: &layoutWeights.heightLength)
        assign(incoming.layout.minWidth, to: \.layout.minWidth, weight: weight, winning: &layoutWeights.minWidth)
        assign(incoming.layout.minHeight, to: \.layout.minHeight, weight: weight, winning: &layoutWeights.minHeight)
        assign(incoming.layout.maxWidth, to: \.layout.maxWidth, weight: weight, winning: &layoutWeights.maxWidth)
        assign(incoming.layout.maxHeight, to: \.layout.maxHeight, weight: weight, winning: &layoutWeights.maxHeight)
        assign(incoming.layout.padding, to: \.layout.padding, weight: weight, winning: &layoutWeights.padding)
        assign(incoming.layout.margin, to: \.layout.margin, weight: weight, winning: &layoutWeights.margin)
        assign(incoming.layout.textAlign, to: \.layout.textAlign, weight: weight, winning: &layoutWeights.textAlign)
        assign(incoming.layout.overflow, to: \.layout.overflow, weight: weight, winning: &layoutWeights.overflow)
        assign(incoming.layout.border, to: \.layout.border, weight: weight, winning: &layoutWeights.border)
        assign(incoming.layout.position, to: \.layout.position, weight: weight, winning: &layoutWeights.position)
        assign(incoming.layout.offset, to: \.layout.offset, weight: weight, winning: &layoutWeights.offset)
        assign(incoming.layout.dividerWidth, to: \.layout.dividerWidth, weight: weight, winning: &layoutWeights.dividerWidth)
        assign(incoming.layout.dividerHeight, to: \.layout.dividerHeight, weight: weight, winning: &layoutWeights.dividerHeight)
        assign(incoming.layout.spacing, to: \.layout.spacing, weight: weight, winning: &layoutWeights.spacing)
        assign(incoming.visual.opacity, to: \.visual.opacity, weight: weight, winning: &visualWeights.opacity)
        assign(incoming.visual.textOpacity, to: \.visual.textOpacity, weight: weight, winning: &visualWeights.textOpacity)
        assign(incoming.visual.display, to: \.visual.display, weight: weight, winning: &visualWeights.display)
        assign(incoming.visual.visibility, to: \.visual.visibility, weight: weight, winning: &visualWeights.visibility)
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
