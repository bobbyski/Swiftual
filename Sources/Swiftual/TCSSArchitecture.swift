import Foundation

public protocol TCSSStyleResolving: Sendable {
    var model: TCSSStyleModel { get }
    var diagnostics: [TCSSDiagnostic] { get }

    func style(for context: TCSSStyleContext) -> TCSSStyle
}

public struct TCSSStyleResolver: TCSSStyleResolving {
    public var model: TCSSStyleModel

    public init(model: TCSSStyleModel) {
        self.model = model
    }

    public init(source: String) {
        self.init(model: TCSSStyleModelBuilder().parse(source))
    }

    public init(sources: [TCSSStylesheetSource]) {
        self.init(model: TCSSStyleModelBuilder().parse(sources))
    }

    public init<Provider: TCSSStylesheetProviding>(providers: [Provider]) {
        self.init(sources: providers.map(\.tcssStylesheetSource))
    }

    public var diagnostics: [TCSSDiagnostic] {
        model.diagnostics
    }

    public func style(for context: TCSSStyleContext) -> TCSSStyle {
        TCSSCascade(model: model).style(for: context)
    }
}

public protocol TCSSStyleApplying: Sendable {
    associatedtype Target

    func apply(_ style: TCSSStyle, to target: inout Target)
}
