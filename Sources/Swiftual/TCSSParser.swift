import Foundation

public struct TCSSStylesheet: Equatable, Sendable {
    public var rules: [TCSSRule]
    public var diagnostics: [TCSSDiagnostic]

    public init(rules: [TCSSRule] = [], diagnostics: [TCSSDiagnostic] = []) {
        self.rules = rules
        self.diagnostics = diagnostics
    }
}

public struct TCSSRule: Equatable, Sendable {
    public var selectors: [TCSSSelector]
    public var declarations: [TCSSDeclaration]
    public var line: Int

    public init(selectors: [TCSSSelector], declarations: [TCSSDeclaration], line: Int) {
        self.selectors = selectors
        self.declarations = declarations
        self.line = line
    }
}

public struct TCSSSelector: Equatable, Sendable {
    public var raw: String
    public var segments: [TCSSSelectorSegment]

    public init(raw: String, segments: [TCSSSelectorSegment]) {
        self.raw = raw
        self.segments = segments
    }
}

public struct TCSSSelectorSegment: Equatable, Sendable {
    public var combinator: TCSSCombinator
    public var typeName: String?
    public var id: String?
    public var classNames: [String]
    public var pseudoStates: [String]

    public init(
        combinator: TCSSCombinator = .none,
        typeName: String? = nil,
        id: String? = nil,
        classNames: [String] = [],
        pseudoStates: [String] = []
    ) {
        self.combinator = combinator
        self.typeName = typeName
        self.id = id
        self.classNames = classNames
        self.pseudoStates = pseudoStates
    }
}

public enum TCSSCombinator: Equatable, Sendable {
    case none
    case descendant
    case child
}

public struct TCSSDeclaration: Equatable, Sendable {
    public var property: String
    public var value: String
    public var line: Int
    public var isImportant: Bool

    public init(property: String, value: String, line: Int, isImportant: Bool = false) {
        self.property = property
        self.value = value
        self.line = line
        self.isImportant = isImportant
    }
}

public struct TCSSDiagnostic: Equatable, Sendable {
    public var line: Int
    public var message: String

    public init(line: Int, message: String) {
        self.line = line
        self.message = message
    }
}

public struct TCSSParser: Sendable {
    public init() {}

    public func parse(_ source: String) -> TCSSStylesheet {
        parseWithVariables(source, inheritedVariables: [:]).stylesheet
    }

    func parseWithVariables(
        _ source: String,
        inheritedVariables: [String: String]
    ) -> (stylesheet: TCSSStylesheet, variables: [String: String]) {
        let stripped = stripComments(from: source)
        let variableExtraction = extractVariables(from: stripped)
        let characters = Array(variableExtraction.source)
        let variables = inheritedVariables.merging(variableExtraction.variables) { _, new in new }
        var diagnostics = variableExtraction.diagnostics
        var rules: [TCSSRule] = []
        var index = 0

        while index < characters.count {
            skipWhitespace(characters, index: &index)
            guard index < characters.count else { break }

            let selectorStart = index
            while index < characters.count, characters[index] != "{", characters[index] != "}" {
                index += 1
            }

            if index >= characters.count {
                let selector = trimmedString(characters[selectorStart..<characters.count])
                if !selector.isEmpty {
                    diagnostics.append(TCSSDiagnostic(line: lineNumber(in: characters, at: selectorStart), message: "Expected '{' after selector '\(selector)'."))
                }
                break
            }

            if characters[index] == "}" {
                diagnostics.append(TCSSDiagnostic(line: lineNumber(in: characters, at: index), message: "Unexpected '}' without a matching block."))
                index += 1
                continue
            }

            let selectorText = trimmedString(characters[selectorStart..<index])
            let selectorLine = lineNumber(in: characters, at: selectorStart)
            index += 1
            let blockStart = index

            while index < characters.count, characters[index] != "}" {
                index += 1
            }

            guard index < characters.count else {
                diagnostics.append(TCSSDiagnostic(line: selectorLine, message: "Unclosed declaration block for selector '\(selectorText)'."))
                let block = String(characters[blockStart..<characters.count])
                let declarations = parseDeclarations(
                    block,
                    baseLine: lineNumber(in: characters, at: blockStart),
                    variables: variables,
                    diagnostics: &diagnostics
                )
                appendRule(selectorText: selectorText, selectorLine: selectorLine, declarations: declarations, rules: &rules, diagnostics: &diagnostics)
                break
            }

            let block = String(characters[blockStart..<index])
            let declarations = parseDeclarations(
                block,
                baseLine: lineNumber(in: characters, at: blockStart),
                variables: variables,
                diagnostics: &diagnostics
            )
            appendRule(selectorText: selectorText, selectorLine: selectorLine, declarations: declarations, rules: &rules, diagnostics: &diagnostics)
            index += 1
        }

        return (TCSSStylesheet(rules: rules, diagnostics: diagnostics), variables)
    }

    private func appendRule(
        selectorText: String,
        selectorLine: Int,
        declarations: [TCSSDeclaration],
        rules: inout [TCSSRule],
        diagnostics: inout [TCSSDiagnostic]
    ) {
        let selectorParts = selectorText.split(separator: ",", omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

        var selectors: [TCSSSelector] = []
        for selectorPart in selectorParts {
            if selectorPart.isEmpty {
                diagnostics.append(TCSSDiagnostic(line: selectorLine, message: "Empty selector in selector list."))
                continue
            }
            selectors.append(parseSelector(selectorPart))
        }

        if selectors.isEmpty {
            diagnostics.append(TCSSDiagnostic(line: selectorLine, message: "Rule ignored because it has no valid selectors."))
            return
        }

        rules.append(TCSSRule(selectors: selectors, declarations: declarations, line: selectorLine))
    }

    private func parseDeclarations(
        _ block: String,
        baseLine: Int,
        variables: [String: String],
        diagnostics: inout [TCSSDiagnostic]
    ) -> [TCSSDeclaration] {
        var declarations: [TCSSDeclaration] = []
        var line = baseLine

        for rawEntry in block.split(separator: ";", omittingEmptySubsequences: false) {
            let entry = String(rawEntry)
            let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
            let entryLine = line + leadingNewlineCount(in: entry)
            defer {
                line += entry.filter { $0 == "\n" }.count
            }

            guard !trimmed.isEmpty else { continue }
            guard let colon = trimmed.firstIndex(of: ":") else {
                diagnostics.append(TCSSDiagnostic(line: entryLine, message: "Expected ':' in declaration '\(trimmed)'."))
                continue
            }

            let property = trimmed[..<colon].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = trimmed[trimmed.index(after: colon)...].trimmingCharacters(in: .whitespacesAndNewlines)

            if property.isEmpty {
                diagnostics.append(TCSSDiagnostic(line: entryLine, message: "Declaration is missing a property name."))
                continue
            }
            if value.isEmpty {
                diagnostics.append(TCSSDiagnostic(line: entryLine, message: "Declaration '\(property)' is missing a value."))
                continue
            }

            let resolvedValue = resolveVariables(in: String(value), variables: variables, line: entryLine, diagnostics: &diagnostics)
            let importance = stripImportant(from: resolvedValue)
            declarations.append(TCSSDeclaration(property: String(property), value: importance.value, line: entryLine, isImportant: importance.isImportant))
        }

        return declarations
    }

    private func stripImportant(from value: String) -> (value: String, isImportant: Bool) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let bangIndex = trimmed.lastIndex(of: "!") else {
            return (trimmed, false)
        }

        let suffix = trimmed[bangIndex...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard suffix == "!important" else {
            return (trimmed, false)
        }

        let valueWithoutImportant = trimmed[..<bangIndex].trimmingCharacters(in: .whitespacesAndNewlines)
        return (String(valueWithoutImportant), true)
    }

    private struct VariableExtraction {
        var source: String
        var variables: [String: String]
        var diagnostics: [TCSSDiagnostic]
    }

    private func extractVariables(from source: String) -> VariableExtraction {
        var characters = Array(source)
        var variables: [String: String] = [:]
        var diagnostics: [TCSSDiagnostic] = []
        var index = 0
        var blockDepth = 0

        while index < characters.count {
            let character = characters[index]
            if character == "{" {
                blockDepth += 1
                index += 1
                continue
            }
            if character == "}" {
                blockDepth = max(0, blockDepth - 1)
                index += 1
                continue
            }
            guard blockDepth == 0, character == "$" else {
                index += 1
                continue
            }

            let variableStart = index
            let line = lineNumber(in: characters, at: variableStart)
            index += 1
            let nameStart = index
            while index < characters.count, isSelectorNameCharacter(characters[index]) {
                index += 1
            }
            let name = String(characters[nameStart..<index])
            guard !name.isEmpty else {
                diagnostics.append(TCSSDiagnostic(line: line, message: "TCSS variable is missing a name."))
                index += 1
                continue
            }

            while index < characters.count, characters[index].isWhitespace {
                index += 1
            }
            guard index < characters.count, characters[index] == ":" else {
                diagnostics.append(TCSSDiagnostic(line: line, message: "Expected ':' after TCSS variable '$\(name)'."))
                continue
            }
            index += 1
            let valueStart = index
            while index < characters.count, characters[index] != ";" {
                index += 1
            }
            guard index < characters.count else {
                diagnostics.append(TCSSDiagnostic(line: line, message: "Expected ';' after TCSS variable '$\(name)'."))
                break
            }

            let value = trimmedString(characters[valueStart..<index])
            if value.isEmpty {
                diagnostics.append(TCSSDiagnostic(line: line, message: "TCSS variable '$\(name)' is missing a value."))
            } else {
                variables[name] = value
            }

            for removeIndex in variableStart...index where characters.indices.contains(removeIndex) {
                if characters[removeIndex] != "\n" {
                    characters[removeIndex] = " "
                }
            }
            index += 1
        }

        return VariableExtraction(source: String(characters), variables: variables, diagnostics: diagnostics)
    }

    private func resolveVariables(
        in value: String,
        variables: [String: String],
        line: Int,
        diagnostics: inout [TCSSDiagnostic]
    ) -> String {
        var stack: [String] = []
        return resolveVariables(in: value, variables: variables, line: line, diagnostics: &diagnostics, stack: &stack)
    }

    private func resolveVariables(
        in value: String,
        variables: [String: String],
        line: Int,
        diagnostics: inout [TCSSDiagnostic],
        stack: inout [String]
    ) -> String {
        let characters = Array(value)
        var output = ""
        var index = 0

        while index < characters.count {
            guard characters[index] == "$" else {
                output.append(characters[index])
                index += 1
                continue
            }

            let dollarIndex = index
            index += 1
            let nameStart = index
            while index < characters.count, isSelectorNameCharacter(characters[index]) {
                index += 1
            }
            let name = String(characters[nameStart..<index])
            guard !name.isEmpty else {
                output.append("$")
                continue
            }
            guard let variableValue = variables[name] else {
                diagnostics.append(TCSSDiagnostic(line: line, message: "Unknown TCSS variable '$\(name)'."))
                output.append(String(characters[dollarIndex..<index]))
                continue
            }
            guard !stack.contains(name) else {
                diagnostics.append(TCSSDiagnostic(line: line, message: "Cyclic TCSS variable reference involving '$\(name)'."))
                output.append(String(characters[dollarIndex..<index]))
                continue
            }

            stack.append(name)
            output += resolveVariables(in: variableValue, variables: variables, line: line, diagnostics: &diagnostics, stack: &stack)
            _ = stack.popLast()
        }

        return output
    }

    private func parseSelector(_ raw: String) -> TCSSSelector {
        var segments: [TCSSSelectorSegment] = []
        var token = ""
        var combinator: TCSSCombinator = .none
        var pendingWhitespace = false

        func flushToken() {
            let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            let effectiveCombinator: TCSSCombinator = segments.isEmpty ? .none : combinator
            segments.append(parseSelectorSegment(trimmed, combinator: effectiveCombinator))
            token = ""
            combinator = .descendant
            pendingWhitespace = false
        }

        for character in raw {
            if character == ">" {
                flushToken()
                combinator = .child
                pendingWhitespace = false
            } else if character.isWhitespace {
                flushToken()
                if !segments.isEmpty, combinator != .child {
                    pendingWhitespace = true
                    combinator = .descendant
                }
            } else {
                if pendingWhitespace, !token.isEmpty {
                    flushToken()
                }
                token.append(character)
                pendingWhitespace = false
            }
        }
        flushToken()

        return TCSSSelector(raw: raw, segments: segments)
    }

    private func parseSelectorSegment(_ token: String, combinator: TCSSCombinator) -> TCSSSelectorSegment {
        let characters = Array(token)
        var index = 0
        var typeName = ""
        var id: String?
        var classNames: [String] = []
        var pseudoStates: [String] = []

        while index < characters.count {
            let marker = characters[index]
            if marker == "*" {
                typeName = "*"
                index += 1
            } else if marker == "." || marker == ":" || marker == "#" {
                index += 1
                let start = index
                while index < characters.count, isSelectorNameCharacter(characters[index]) {
                    index += 1
                }
                let name = String(characters[start..<index])
                guard !name.isEmpty else { continue }
                if marker == "." {
                    classNames.append(name)
                } else if marker == ":" {
                    pseudoStates.append(name)
                } else {
                    id = name
                }
            } else {
                let start = index
                while index < characters.count, isSelectorNameCharacter(characters[index]) {
                    index += 1
                }
                if start == index {
                    index += 1
                } else {
                    typeName += String(characters[start..<index])
                }
            }
        }

        return TCSSSelectorSegment(
            combinator: combinator,
            typeName: typeName.isEmpty ? nil : typeName,
            id: id,
            classNames: classNames,
            pseudoStates: pseudoStates
        )
    }

    private func stripComments(from source: String) -> String {
        let characters = Array(source)
        var output = ""
        var index = 0

        while index < characters.count {
            if index + 1 < characters.count, characters[index] == "/", characters[index + 1] == "*" {
                index += 2
                while index + 1 < characters.count, !(characters[index] == "*" && characters[index + 1] == "/") {
                    if characters[index] == "\n" {
                        output.append("\n")
                    } else {
                        output.append(" ")
                    }
                    index += 1
                }
                if index + 1 < characters.count {
                    output.append("  ")
                    index += 2
                }
            } else {
                output.append(characters[index])
                index += 1
            }
        }

        return output
    }

    private func skipWhitespace(_ characters: [Character], index: inout Int) {
        while index < characters.count, characters[index].isWhitespace {
            index += 1
        }
    }

    private func trimmedString(_ slice: ArraySlice<Character>) -> String {
        String(slice).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func lineNumber(in characters: [Character], at target: Int) -> Int {
        guard target > 0 else { return 1 }
        return characters[..<min(target, characters.count)].reduce(1) { partial, character in
            partial + (character == "\n" ? 1 : 0)
        }
    }

    private func leadingNewlineCount(in text: String) -> Int {
        var count = 0
        for character in text {
            if character == "\n" {
                count += 1
            } else if !character.isWhitespace {
                break
            }
        }
        return count
    }

    private func isSelectorNameCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "-" || character == "_"
    }
}
