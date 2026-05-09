import Foundation

public struct TSSDemoStylesheet: Equatable, Sendable {
    public var fileName: String
    public var source: String

    public init(fileName: String, source: String) {
        self.fileName = fileName
        self.source = source
    }
}

public struct TSSDemoViewContainer: Equatable, Sendable {
    public var baseDemo: MainViewContainer
    public var stylesheets: [TSSDemoStylesheet]
    public var selectedStylesheetIndex: Int
    public var styleSelector: Select
    public var sourceView: ScrollView
    public var focusedPanelControl: TSSDemoPanelFocus
    public var panelWidth: Int
    public var panelStyle: TerminalStyle
    public var titleStyle: TerminalStyle

    public init(
        baseDemo: MainViewContainer,
        stylesheets: [TSSDemoStylesheet] = TSSDemoViewContainer.defaultStylesheets(),
        selectedStylesheetIndex: Int = 0,
        panelWidth: Int = 54,
        panelStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        titleStyle: TerminalStyle = TerminalStyle(foreground: .black, background: .cyan, bold: true)
    ) {
        self.baseDemo = baseDemo
        self.stylesheets = stylesheets
        self.selectedStylesheetIndex = stylesheets.indices.contains(selectedStylesheetIndex) ? selectedStylesheetIndex : 0
        self.styleSelector = Select(frame: Rect(x: 0, y: 0, width: 1, height: 1), options: stylesheets.map { SelectOption($0.fileName) })
        self.sourceView = ScrollView(frame: Rect(x: 0, y: 0, width: 1, height: 1), content: [])
        self.focusedPanelControl = .selector
        self.panelWidth = panelWidth
        self.panelStyle = panelStyle
        self.titleStyle = titleStyle
        updatePanelControls(for: TerminalSize(columns: 180, rows: 32))
    }

    public mutating func handle(_ event: InputEvent, terminalSize: TerminalSize = TerminalSize(columns: 180, rows: 32)) -> MenuCommand {
        updatePanelControls(for: terminalSize)

        if case .mouse(let mouse) = event, panelFrame(for: terminalSize).contains(mouse.location) {
            if styleSelector.frame.contains(mouse.location) || styleSelector.isOpen {
                focusedPanelControl = .selector
                styleSelector.isFocused = true
                let command = styleSelector.handle(event)
                applySelectorCommand(command)
                return .none
            }
            if sourceView.frame.contains(mouse.location) {
                focusedPanelControl = .source
                sourceView.isFocused = true
                _ = sourceView.handle(event)
                return .none
            }
        }

        switch focusedPanelControl {
        case .selector:
            styleSelector.isFocused = true
            let command = styleSelector.handle(event)
            if command != .none {
                applySelectorCommand(command)
                return .none
            }
        case .source:
            sourceView.isFocused = true
            if sourceView.handle(event) != .none {
                return .none
            }
        }

        let command = baseDemo.handle(event)
        return command
    }

    public mutating func updateProgressAnimation(now: Date = Date()) {
        baseDemo.updateProgressAnimation(now: now)
    }

    public mutating func updateWorkerEvents() {
        baseDemo.updateWorkerEvents()
    }

    public mutating func render(size: TerminalSize) -> Canvas {
        updatePanelControls(for: size)
        var canvas = baseDemo.render(size: size)
        renderPanel(in: &canvas, size: size)
        return canvas
    }

    private mutating func applySelectorCommand(_ command: SelectCommand) {
        guard case .changed(let index, _) = command else { return }
        selectedStylesheetIndex = index
        sourceView.scrollOffset = 0
        updateSourceContent()
        baseDemo.richLog.append("TCSS demo selected: \(selectedStylesheet.fileName).", style: TerminalStyle(foreground: .cyan, background: .black))
    }

    private mutating func updatePanelControls(for size: TerminalSize) {
        let frame = panelFrame(for: size)
        let selectorWidth = max(1, frame.width - 4)
        styleSelector.frame = Rect(x: frame.x + 2, y: frame.y + 3, width: selectorWidth, height: 1)
        styleSelector.options = stylesheets.map { SelectOption($0.fileName) }
        styleSelector.selectedIndex = selectedStylesheetIndex
        if !styleSelector.isOpen {
            styleSelector.highlightedIndex = selectedStylesheetIndex
        }
        sourceView.frame = Rect(x: frame.x + 2, y: frame.y + 6, width: selectorWidth, height: max(1, frame.height - 8))
        updateSourceContent()
    }

    private mutating func updateSourceContent() {
        sourceView.content = selectedStylesheet.source.components(separatedBy: .newlines)
        sourceView.contentHeight = sourceView.content.count
        sourceView.scrollOffset = min(sourceView.scrollOffset, max(0, sourceView.content.count - sourceView.frame.height))
    }

    private func renderPanel(in canvas: inout Canvas, size: TerminalSize) {
        let frame = panelFrame(for: size)
        guard frame.width > 0, frame.height > 0 else { return }
        canvas.fill(rect: frame, style: panelStyle)
        canvas.fill(rect: Rect(x: frame.x, y: frame.y, width: 1, height: frame.height), style: TerminalStyle(foreground: .brightWhite, background: .blue), character: " ")
        Label("TCSS test files", frame: Rect(x: frame.x + 2, y: frame.y + 1, width: max(0, frame.width - 4), height: 1), style: titleStyle).render(in: &canvas)
        Label("Selected stylesheet", frame: Rect(x: frame.x + 2, y: frame.y + 2, width: max(0, frame.width - 4), height: 1), style: panelStyle).render(in: &canvas)
        Label("Source preview", frame: Rect(x: frame.x + 2, y: frame.y + 5, width: max(0, frame.width - 4), height: 1), style: panelStyle).render(in: &canvas)
        sourceView.render(in: &canvas)
        styleSelector.render(in: &canvas)
    }

    private var selectedStylesheet: TSSDemoStylesheet {
        guard stylesheets.indices.contains(selectedStylesheetIndex) else {
            return TSSDemoStylesheet(fileName: "empty.tcss", source: "")
        }
        return stylesheets[selectedStylesheetIndex]
    }

    private func panelFrame(for size: TerminalSize) -> Rect {
        let width = min(panelWidth, max(0, size.columns))
        return Rect(x: max(0, size.columns - width), y: 1, width: width, height: max(0, size.rows - 1))
    }

    public static func frozenBaseDemo() -> MainViewContainer {
        MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit", shortcut: "Q") {}
                    ])
                ]
            )
        )
    }

    public static func defaultStylesheets() -> [TSSDemoStylesheet] {
        [
            TSSDemoStylesheet(
                fileName: "00-baseline.tcss",
                source: """
                /* Baseline captures the frozen Swift styling. */
                Screen {
                    background: bright-black;
                    color: bright-white;
                }

                MenuBar {
                    background: blue;
                    color: bright-white;
                }
                """
            ),
            TSSDemoStylesheet(
                fileName: "01-buttons-labels.tcss",
                source: """
                /* First parser target: Button and Label. */
                Button {
                    background: bright-white;
                    color: black;
                    height: 1;
                }

                Button:focus {
                    background: blue;
                    color: bright-white;
                    text-style: bold;
                }

                Label.centered {
                    background: cyan;
                    color: black;
                    text-align: center;
                }
                """
            ),
            TSSDemoStylesheet(
                fileName: "02-inputs-choice.tcss",
                source: """
                /* Next target: input and choice controls. */
                TextInput:focus {
                    background: blue;
                    color: bright-white;
                }

                Checkbox:checked,
                Switch:on {
                    background: green;
                    color: black;
                }

                Select:open {
                    background: bright-white;
                    color: black;
                }
                """
            ),
            TSSDemoStylesheet(
                fileName: "03-data-navigation.tcss",
                source: """
                /* Later target: scrollable and structured controls. */
                DataTable > Header {
                    background: cyan;
                    color: black;
                    text-style: bold;
                }

                Tree:selected,
                ScrollView ScrollBarThumb {
                    background: blue;
                    color: bright-white;
                }

                RichLog {
                    background: black;
                    color: bright-white;
                }
                """
            )
        ]
    }
}

public enum TSSDemoPanelFocus: Equatable, Sendable {
    case selector
    case source
}
