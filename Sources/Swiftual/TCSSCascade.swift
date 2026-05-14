import Foundation

public struct TCSSStyleContextNode: Equatable, Sendable {
    public var typeName: String
    public var typeNames: Set<String>
    public var id: String?
    public var classNames: Set<String>
    public var pseudoStates: Set<String>

    public init(
        typeName: String,
        typeNames: Set<String> = [],
        id: String? = nil,
        classNames: Set<String> = [],
        pseudoStates: Set<String> = []
    ) {
        self.typeName = typeName
        self.typeNames = typeNames.union([typeName])
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
        typeNames: Set<String> = [],
        id: String? = nil,
        classNames: Set<String> = [],
        pseudoStates: Set<String> = [],
        ancestors: [TCSSStyleContextNode] = []
    ) {
        self.node = TCSSStyleContextNode(
            typeName: typeName,
            typeNames: typeNames,
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
        typeNames: Set<String> = [],
        id: String? = nil,
        classNames: Set<String> = [],
        pseudoStates: Set<String> = []
    ) -> TCSSStyleContext {
        TCSSStyleContext(
            typeName: typeName,
            typeNames: typeNames,
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
                let weight = TCSSCascadeWeight(isImportant: false, specificity: selector.specificity, sourceOrder: ruleIndex)
                resolved.merge(rule.style, weight: weight, terminalWeights: &winningTerminal, layoutWeights: &winningLayout, visualWeights: &winningVisual)
            }
        }

        return resolved
    }
}

private struct TCSSCascadeWeight: Comparable {
    var isImportant: Bool
    var specificity: TCSSSelectorSpecificity
    var sourceOrder: Int

    static func < (lhs: TCSSCascadeWeight, rhs: TCSSCascadeWeight) -> Bool {
        if lhs.isImportant != rhs.isImportant {
            return !lhs.isImportant && rhs.isImportant
        }
        if lhs.specificity != rhs.specificity {
            return lhs.specificity < rhs.specificity
        }
        return lhs.sourceOrder < rhs.sourceOrder
    }
}

private struct TCSSSelectorSpecificity: Comparable, Equatable {
    var ids: Int
    var classes: Int
    var types: Int

    static func < (lhs: TCSSSelectorSpecificity, rhs: TCSSSelectorSpecificity) -> Bool {
        if lhs.ids != rhs.ids {
            return lhs.ids < rhs.ids
        }
        if lhs.classes != rhs.classes {
            return lhs.classes < rhs.classes
        }
        return lhs.types < rhs.types
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
    var gridSize: TCSSCascadeWeight?
    var gridGutter: TCSSCascadeWeight?
    var opacity: TCSSCascadeWeight?
    var textOpacity: TCSSCascadeWeight?
    var display: TCSSCascadeWeight?
    var visibility: TCSSCascadeWeight?
}

private extension TCSSSelector {
    var specificity: TCSSSelectorSpecificity {
        segments.reduce(TCSSSelectorSpecificity(ids: 0, classes: 0, types: 0)) { partial, segment in
            TCSSSelectorSpecificity(
                ids: partial.ids + (segment.id == nil ? 0 : 1),
                classes: partial.classes + segment.classNames.count + segment.pseudoStates.count,
                types: partial.types + ((segment.typeName == nil || segment.typeName == "*") ? 0 : 1)
            )
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
        if let typeName, typeName != "*", !context.typeNames.contains(typeName) {
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
        assign(incoming.terminalStyle.foreground, to: \.terminalStyle.foreground, weight: weight, isImportant: incoming.importance.foreground, winning: &terminalWeights.foreground)
        assign(incoming.terminalStyle.background, to: \.terminalStyle.background, weight: weight, isImportant: incoming.importance.background, winning: &terminalWeights.background)
        assign(incoming.terminalStyle.bold, to: \.terminalStyle.bold, weight: weight, isImportant: incoming.importance.bold, winning: &terminalWeights.bold)
        assign(incoming.terminalStyle.dim, to: \.terminalStyle.dim, weight: weight, isImportant: incoming.importance.dim, winning: &terminalWeights.dim)
        assign(incoming.terminalStyle.italic, to: \.terminalStyle.italic, weight: weight, isImportant: incoming.importance.italic, winning: &terminalWeights.italic)
        assign(incoming.terminalStyle.underline, to: \.terminalStyle.underline, weight: weight, isImportant: incoming.importance.underline, winning: &terminalWeights.underline)
        assign(incoming.terminalStyle.strikethrough, to: \.terminalStyle.strikethrough, weight: weight, isImportant: incoming.importance.strikethrough, winning: &terminalWeights.strikethrough)
        assign(incoming.terminalStyle.inverse, to: \.terminalStyle.inverse, weight: weight, isImportant: incoming.importance.inverse, winning: &terminalWeights.inverse)
        assign(incoming.terminalStyle.blink, to: \.terminalStyle.blink, weight: weight, isImportant: incoming.importance.blink, winning: &terminalWeights.blink)
        assign(incoming.layout.layoutKind, to: \.layout.layoutKind, weight: weight, isImportant: incoming.importance.layoutKind, winning: &layoutWeights.layoutKind)
        assign(incoming.layout.dock, to: \.layout.dock, weight: weight, isImportant: incoming.importance.dock, winning: &layoutWeights.dock)
        assign(incoming.layout.align, to: \.layout.align, weight: weight, isImportant: incoming.importance.align, winning: &layoutWeights.align)
        assign(incoming.layout.contentAlign, to: \.layout.contentAlign, weight: weight, isImportant: incoming.importance.contentAlign, winning: &layoutWeights.contentAlign)
        assign(incoming.layout.layer, to: \.layout.layer, weight: weight, isImportant: incoming.importance.layer, winning: &layoutWeights.layer)
        assign(incoming.layout.layers, to: \.layout.layers, weight: weight, isImportant: incoming.importance.layers, winning: &layoutWeights.layers)
        assign(incoming.layout.width, to: \.layout.width, weight: weight, isImportant: incoming.importance.width, winning: &layoutWeights.width)
        assign(incoming.layout.height, to: \.layout.height, weight: weight, isImportant: incoming.importance.height, winning: &layoutWeights.height)
        assign(incoming.layout.widthLength, to: \.layout.widthLength, weight: weight, isImportant: incoming.importance.widthLength, winning: &layoutWeights.widthLength)
        assign(incoming.layout.heightLength, to: \.layout.heightLength, weight: weight, isImportant: incoming.importance.heightLength, winning: &layoutWeights.heightLength)
        assign(incoming.layout.minWidth, to: \.layout.minWidth, weight: weight, isImportant: incoming.importance.minWidth, winning: &layoutWeights.minWidth)
        assign(incoming.layout.minHeight, to: \.layout.minHeight, weight: weight, isImportant: incoming.importance.minHeight, winning: &layoutWeights.minHeight)
        assign(incoming.layout.maxWidth, to: \.layout.maxWidth, weight: weight, isImportant: incoming.importance.maxWidth, winning: &layoutWeights.maxWidth)
        assign(incoming.layout.maxHeight, to: \.layout.maxHeight, weight: weight, isImportant: incoming.importance.maxHeight, winning: &layoutWeights.maxHeight)
        assign(incoming.layout.padding, to: \.layout.padding, weight: weight, isImportant: incoming.importance.padding, winning: &layoutWeights.padding)
        assign(incoming.layout.margin, to: \.layout.margin, weight: weight, isImportant: incoming.importance.margin, winning: &layoutWeights.margin)
        assign(incoming.layout.textAlign, to: \.layout.textAlign, weight: weight, isImportant: incoming.importance.textAlign, winning: &layoutWeights.textAlign)
        assign(incoming.layout.overflow, to: \.layout.overflow, weight: weight, isImportant: incoming.importance.overflow, winning: &layoutWeights.overflow)
        assign(incoming.layout.border, to: \.layout.border, weight: weight, isImportant: incoming.importance.border, winning: &layoutWeights.border)
        assign(incoming.layout.position, to: \.layout.position, weight: weight, isImportant: incoming.importance.position, winning: &layoutWeights.position)
        assign(incoming.layout.offset, to: \.layout.offset, weight: weight, isImportant: incoming.importance.offset, winning: &layoutWeights.offset)
        assign(incoming.layout.dividerWidth, to: \.layout.dividerWidth, weight: weight, isImportant: incoming.importance.dividerWidth, winning: &layoutWeights.dividerWidth)
        assign(incoming.layout.dividerHeight, to: \.layout.dividerHeight, weight: weight, isImportant: incoming.importance.dividerHeight, winning: &layoutWeights.dividerHeight)
        assign(incoming.layout.spacing, to: \.layout.spacing, weight: weight, isImportant: incoming.importance.spacing, winning: &layoutWeights.spacing)
        assign(incoming.layout.gridSize, to: \.layout.gridSize, weight: weight, isImportant: incoming.importance.gridSize, winning: &layoutWeights.gridSize)
        assign(incoming.layout.gridGutter, to: \.layout.gridGutter, weight: weight, isImportant: incoming.importance.gridGutter, winning: &layoutWeights.gridGutter)
        assign(incoming.visual.opacity, to: \.visual.opacity, weight: weight, isImportant: incoming.importance.opacity, winning: &visualWeights.opacity)
        assign(incoming.visual.textOpacity, to: \.visual.textOpacity, weight: weight, isImportant: incoming.importance.textOpacity, winning: &visualWeights.textOpacity)
        assign(incoming.visual.display, to: \.visual.display, weight: weight, isImportant: incoming.importance.display, winning: &visualWeights.display)
        assign(incoming.visual.visibility, to: \.visual.visibility, weight: weight, isImportant: incoming.importance.visibility, winning: &visualWeights.visibility)
    }

    mutating func assign<Value>(
        _ value: Value?,
        to keyPath: WritableKeyPath<TCSSStyle, Value?>,
        weight: TCSSCascadeWeight,
        isImportant: Bool?,
        winning: inout TCSSCascadeWeight?
    ) {
        guard let value else { return }
        var propertyWeight = weight
        propertyWeight.isImportant = isImportant == true
        if let winning, winning > propertyWeight {
            return
        }
        self[keyPath: keyPath] = value
        winning = propertyWeight
    }
}
