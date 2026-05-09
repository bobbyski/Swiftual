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
    public var sourceView: SyntaxHighlightedScrollView
    public var focusedPanelControl: TSSDemoPanelFocus
    public var panelWidth: Int
    public var splitView: HorizontalSplitView
    public var panelStyle: TerminalStyle
    public var titleStyle: TerminalStyle
    public var stylesheetDiagnostics: [TCSSDiagnostic]

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
        self.sourceView = SyntaxHighlightedScrollView(frame: Rect(x: 0, y: 0, width: 1, height: 1), source: "")
        self.focusedPanelControl = .selector
        self.panelWidth = panelWidth
        self.splitView = HorizontalSplitView(
            frame: Rect(x: 0, y: 1, width: 180, height: 31),
            dividerOffset: max(10, 180 - panelWidth),
            minLeading: 60,
            minTrailing: 32
        )
        self.panelStyle = panelStyle
        self.titleStyle = titleStyle
        self.stylesheetDiagnostics = []
        updatePanelControls(for: TerminalSize(columns: 180, rows: 32))
        applySelectedStylesheet(logSelection: false)
    }

    public mutating func handle(_ event: InputEvent, terminalSize: TerminalSize = TerminalSize(columns: 180, rows: 32)) -> MenuCommand {
        updatePanelControls(for: terminalSize)

        if case .mouse = event {
            let splitCommand = splitView.handle(event)
            if splitCommand != .none {
                updatePanelControls(for: terminalSize)
                return .none
            }
        }

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

        let command = baseDemo.handle(event, terminalSize: leftTerminalSize(for: terminalSize))
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
        var canvas = Canvas(size: size, fill: Cell(" ", style: baseDemo.backgroundStyle))
        let leftFrame = splitView.leadingFrame
        let leftCanvas = baseDemo.render(size: leftTerminalSize(for: size))
        for row in 0..<size.rows {
            for column in 0..<leftFrame.width {
                canvas[leftFrame.x + column, row] = leftCanvas[column, row]
            }
        }
        splitView.render(in: &canvas)
        renderPanel(in: &canvas, size: size)
        return canvas
    }

    private mutating func applySelectorCommand(_ command: SelectCommand) {
        guard case .changed(let index, _) = command else { return }
        selectedStylesheetIndex = index
        sourceView.scrollOffset = 0
        updateSourceContent()
        applySelectedStylesheet(logSelection: true)
    }

    private mutating func applySelectedStylesheet(logSelection: Bool) {
        resetDemoStyles()
        let model = TCSSStyleModelBuilder().parse(selectedStylesheet.source)
        stylesheetDiagnostics = model.diagnostics
        let cascade = TCSSCascade(model: model)

        let screenStyle = cascade.style(for: TCSSStyleContext(typeName: "Screen"))
        baseDemo.backgroundStyle = screenStyle.terminalStyle.applied(to: baseDemo.backgroundStyle)

        let menuBarStyle = cascade.style(for: TCSSStyleContext(typeName: "MenuBar"))
        baseDemo.menuBar.barStyle = menuBarStyle.terminalStyle.applied(to: baseDemo.menuBar.barStyle)
        baseDemo.menuBar.selectedBarStyle = menuBarStyle.terminalStyle.applied(to: baseDemo.menuBar.selectedBarStyle)

        if logSelection {
            baseDemo.richLog.append("TCSS demo selected: \(selectedStylesheet.fileName).", style: TerminalStyle(foreground: .cyan, background: .black))
            if !stylesheetDiagnostics.isEmpty {
                baseDemo.richLog.append("TCSS diagnostics: \(stylesheetDiagnostics.count) issue(s).", style: TerminalStyle(foreground: .yellow, background: .black))
            }
        }
    }

    private mutating func resetDemoStyles() {
        baseDemo.backgroundStyle = TerminalStyle(foreground: .brightWhite, background: .brightBlack)
        baseDemo.menuBar.resetStyles()
    }

    private mutating func updatePanelControls(for size: TerminalSize) {
        let oldFrame = splitView.frame
        let oldTrailingWidth = oldFrame.width > 0 ? splitView.trailingFrame.width : max(0, panelWidth - splitView.dividerWidth)
        splitView.frame = Rect(x: 0, y: 1, width: size.columns, height: max(0, size.rows - 1))
        if oldFrame.width != splitView.frame.width {
            splitView.dividerOffset = max(0, splitView.frame.width - splitView.dividerWidth - oldTrailingWidth)
        }

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
        sourceView.source = selectedStylesheet.source
        sourceView.scrollOffset = min(sourceView.scrollOffset, max(0, sourceView.contentHeight - sourceView.frame.height))
    }

    private func renderPanel(in canvas: inout Canvas, size: TerminalSize) {
        let frame = panelFrame(for: size)
        guard frame.width > 0, frame.height > 0 else { return }
        canvas.fill(rect: frame, style: panelStyle)
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
        splitView.trailingFrame
    }

    private func leftTerminalSize(for size: TerminalSize) -> TerminalSize {
        TerminalSize(columns: max(1, splitView.leadingFrame.width), rows: size.rows)
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
                fileName: "01-current-target.tcss",
                source: """
                /* Current target set for the active implementation step.
                   Use this file to isolate whichever controls we are touching now.
                   TCSS should eventually apply across every matching control. */
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
                fileName: "02-pseudo-states.tcss",
                source: """
                /* Feature set: pseudo-states on any control that exposes state. */
                Button:focus,
                TextInput:focus,
                Select:open,
                Tree:selected,
                DataTable:selected {
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
                fileName: "03-combinators.tcss",
                source: """
                /* Feature set: child and descendant selector matching. */
                MenuBar > Menu {
                    background: blue;
                    color: bright-white;
                }

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
            ),
            TSSDemoStylesheet(
                fileName: "04-big.tcss",
                source: """
                /* Edge case: absurdly large element requests.
                   This is for parser/model/layout stress testing, not good UI. */
                Button,
                TextInput,
                Select {
                    width: 120;
                    height: 8;
                    padding: 6;
                }

                Modal {
                    width: 160;
                    height: 40;
                    padding: 8;
                }

                ProgressBar,
                RichLog,
                DataTable,
                Tree {
                    width: 180;
                    height: 30;
                }
                """
            ),
            TSSDemoStylesheet(
                fileName: "05-small.tcss",
                source: """
                /* Edge case: tiny element requests.
                   Controls should clamp, crop, or degrade predictably. */
                Button,
                TextInput,
                Select,
                ProgressBar {
                    width: 1;
                    height: 1;
                    padding: 0;
                }

                Modal,
                RichLog,
                DataTable,
                Tree,
                ScrollView {
                    width: 2;
                    height: 1;
                    padding: 0;
                }
                """
            ),
            TSSDemoStylesheet(
                fileName: "06-that70sShow.tcss",
                source: """
                /* Never do this, but it is good to know you can.
                   Obnoxious 1970s hippie-van color flexibility demo. */
                Screen {
                    background: rgb(255, 112, 67);
                    color: rgb(0, 255, 213);
                }

                MenuBar,
                Button:focus {
                    background: rgb(156, 39, 176);
                    color: rgb(255, 235, 59);
                    text-style: bold;
                }

                Label.centered,
                ProgressBar {
                    background: rgb(0, 188, 212);
                    color: rgb(255, 64, 129);
                }

                Checkbox:checked,
                Switch:on,
                Select:open {
                    background: rgb(139, 195, 74);
                    color: rgb(74, 20, 140);
                    text-style: bold;
                }

                RichLog,
                DataTable > Header,
                Tree:selected {
                    background: rgb(255, 193, 7);
                    color: rgb(63, 81, 181);
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
