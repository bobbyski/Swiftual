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
        let menuBar = baseDemo.menuBar
        menuBar.render(in: &canvas)
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

        let menuStyle = cascade.style(for: TCSSStyleContext(typeName: "Menu"))
        baseDemo.menuBar.menuStyle = menuStyle.terminalStyle.applied(to: baseDemo.menuBar.menuStyle)

        let menuItemStyle = cascade.style(for: TCSSStyleContext(typeName: "MenuItem"))
        baseDemo.menuBar.selectedItemStyle = menuItemStyle.terminalStyle.applied(to: baseDemo.menuBar.selectedItemStyle)

        let disabledMenuItemStyle = cascade.style(for: TCSSStyleContext(typeName: "MenuItem", pseudoStates: ["disabled"]))
        baseDemo.menuBar.disabledItemStyle = disabledMenuItemStyle.terminalStyle.applied(to: baseDemo.menuBar.disabledItemStyle)

        applyLabelTCSS(cascade)
        applyButtonTCSS(cascade)
        applyContainerTCSS(cascade)
        applyInputAndChoiceTCSS(cascade)
        applyScrollableTCSS(cascade)
        applyOverlayAndProgressTCSS(cascade)
        applyDataControlsTCSS(cascade)
        applyCommandAndWorkerTCSS(cascade)

        if logSelection {
            baseDemo.richLog.append("TCSS demo selected: \(selectedStylesheet.fileName).", style: TerminalStyle(foreground: .cyan, background: .black))
            if !stylesheetDiagnostics.isEmpty {
                baseDemo.richLog.append("TCSS diagnostics: \(stylesheetDiagnostics.count) issue(s).", style: TerminalStyle(foreground: .yellow, background: .black))
            }
        }
    }

    private mutating func applyLabelTCSS(_ cascade: TCSSCascade) {
        for index in baseDemo.demoLabels.indices {
            let className = switch index {
            case 0: "left"
            case 1: "centered"
            case 2: "right"
            default: "label"
            }
            let base = cascade.style(for: TCSSStyleContext(typeName: "Label"))
            let specialized = cascade.style(for: TCSSStyleContext(typeName: "Label", classNames: [className]))
            baseDemo.demoLabels[index].style = base.terminalStyle.applied(to: baseDemo.demoLabels[index].style)
            baseDemo.demoLabels[index].style = specialized.terminalStyle.applied(to: baseDemo.demoLabels[index].style)
            baseDemo.demoLabels[index].frame = apply(base.layout, to: baseDemo.demoLabels[index].frame)
            baseDemo.demoLabels[index].frame = apply(specialized.layout, to: baseDemo.demoLabels[index].frame)
            if let alignment = specialized.layout.textAlign ?? base.layout.textAlign {
                baseDemo.demoLabels[index].alignment = textAlignment(from: alignment)
            }
        }
    }

    private mutating func applyButtonTCSS(_ cascade: TCSSCascade) {
        let buttonStyle = cascade.style(for: TCSSStyleContext(typeName: "Button"))
        let focusedButtonStyle = cascade.style(for: TCSSStyleContext(typeName: "Button", pseudoStates: ["focus"]))
        let disabledButtonStyle = cascade.style(for: TCSSStyleContext(typeName: "Button", pseudoStates: ["disabled"]))

        apply(
            buttonStyle: buttonStyle,
            focusedButtonStyle: focusedButtonStyle,
            disabledButtonStyle: disabledButtonStyle,
            to: &baseDemo.button
        )

        for index in baseDemo.demoButtons.indices {
            apply(
                buttonStyle: buttonStyle,
                focusedButtonStyle: focusedButtonStyle,
                disabledButtonStyle: disabledButtonStyle,
                to: &baseDemo.demoButtons[index]
            )
        }
    }

    private mutating func applyContainerTCSS(_ cascade: TCSSCascade) {
        let showcase = cascade.style(for: TCSSStyleContext(typeName: "Showcase"))
        baseDemo.showcasePreferences = layoutPreferences(from: showcase.layout, fallback: baseDemo.showcasePreferences)

        let introPanel = cascade.style(for: TCSSStyleContext(typeName: "IntroPanel"))
        baseDemo.introPanelPreferences = layoutPreferences(from: introPanel.layout, fallback: baseDemo.introPanelPreferences)

        let formRow = cascade.style(for: TCSSStyleContext(typeName: "FormRow"))
        baseDemo.formControlsPreferences = layoutPreferences(from: formRow.layout, fallback: baseDemo.formControlsPreferences)

        let labelButtonPanel = cascade.style(for: TCSSStyleContext(typeName: "LabelButtonPanel"))
        baseDemo.labelButtonPanelPreferences = layoutPreferences(from: labelButtonPanel.layout, fallback: baseDemo.labelButtonPanelPreferences)

        let containerRow = cascade.style(for: TCSSStyleContext(typeName: "ContainerRow"))
        baseDemo.containerPanelPreferences = layoutPreferences(from: containerRow.layout, fallback: baseDemo.containerPanelPreferences)

        let actionsRow = cascade.style(for: TCSSStyleContext(typeName: "ActionsRow"))
        baseDemo.actionsPanelPreferences = layoutPreferences(from: actionsRow.layout, fallback: baseDemo.actionsPanelPreferences)

        let vertical = cascade.style(for: TCSSStyleContext(typeName: "Vertical"))
        baseDemo.verticalFillStyle = vertical.terminalStyle.applied(to: baseDemo.verticalFillStyle)
        baseDemo.verticalTitleStyle = vertical.terminalStyle.applied(to: baseDemo.verticalTitleStyle)
        baseDemo.verticalChildLabelStyle = vertical.terminalStyle.applied(to: baseDemo.verticalChildLabelStyle)
        baseDemo.verticalChildButtonStyle = vertical.terminalStyle.applied(to: baseDemo.verticalChildButtonStyle)

        let horizontal = cascade.style(for: TCSSStyleContext(typeName: "Horizontal"))
        baseDemo.horizontalFillStyle = horizontal.terminalStyle.applied(to: baseDemo.horizontalFillStyle)
        baseDemo.horizontalLabelStyle = horizontal.terminalStyle.applied(to: baseDemo.horizontalLabelStyle)
        baseDemo.horizontalButtonStyle = horizontal.terminalStyle.applied(to: baseDemo.horizontalButtonStyle)
        baseDemo.horizontalFocusedButtonStyle = horizontal.terminalStyle.applied(to: baseDemo.horizontalFocusedButtonStyle)

        let split = cascade.style(for: TCSSStyleContext(typeName: "SplitView"))
        splitView.dividerStyle = split.terminalStyle.applied(to: splitView.dividerStyle)
        if let dividerWidth = split.layout.dividerWidth {
            splitView.dividerWidth = max(1, dividerWidth)
        }
        if let dividerHeight = split.layout.dividerHeight {
            baseDemo.logSplitDividerOffset = baseDemo.logSplitDividerOffset
            _ = dividerHeight
        }
    }

    private mutating func applyInputAndChoiceTCSS(_ cascade: TCSSCascade) {
        let textInput = cascade.style(for: TCSSStyleContext(typeName: "TextInput"))
        let textInputFocus = cascade.style(for: TCSSStyleContext(typeName: "TextInput", pseudoStates: ["focus"]))
        let placeholder = cascade.style(for: TCSSStyleContext(typeName: "Placeholder"))
        let cursor = cascade.style(for: TCSSStyleContext(typeName: "Cursor"))
        baseDemo.textInput.style = textInput.terminalStyle.applied(to: baseDemo.textInput.style)
        baseDemo.textInput.focusedStyle = textInputFocus.terminalStyle.applied(to: baseDemo.textInput.focusedStyle)
        baseDemo.textInput.placeholderStyle = placeholder.terminalStyle.applied(to: baseDemo.textInput.placeholderStyle)
        baseDemo.textInput.cursorStyle = cursor.terminalStyle.applied(to: baseDemo.textInput.cursorStyle)
        baseDemo.textInput.frame = apply(textInput.layout, to: baseDemo.textInput.frame)

        let checkbox = cascade.style(for: TCSSStyleContext(typeName: "Checkbox"))
        let checkboxFocus = cascade.style(for: TCSSStyleContext(typeName: "Checkbox", pseudoStates: ["focus"]))
        let checkboxChecked = cascade.style(for: TCSSStyleContext(typeName: "Checkbox", pseudoStates: ["checked"]))
        let checkboxDisabled = cascade.style(for: TCSSStyleContext(typeName: "Checkbox", pseudoStates: ["disabled"]))
        baseDemo.checkbox.style = checkbox.terminalStyle.applied(to: baseDemo.checkbox.style)
        baseDemo.checkbox.focusedStyle = checkboxFocus.terminalStyle.applied(to: baseDemo.checkbox.focusedStyle)
        baseDemo.checkbox.checkedStyle = checkboxChecked.terminalStyle.applied(to: baseDemo.checkbox.checkedStyle)
        baseDemo.checkbox.focusedCheckedStyle = checkboxChecked.terminalStyle.applied(to: baseDemo.checkbox.focusedCheckedStyle)
        baseDemo.checkbox.focusedCheckedStyle = checkboxFocus.terminalStyle.applied(to: baseDemo.checkbox.focusedCheckedStyle)
        baseDemo.checkbox.disabledStyle = checkboxDisabled.terminalStyle.applied(to: baseDemo.checkbox.disabledStyle)
        baseDemo.checkbox.frame = apply(checkbox.layout, to: baseDemo.checkbox.frame)

        let switchBase = cascade.style(for: TCSSStyleContext(typeName: "Switch"))
        let switchOn = cascade.style(for: TCSSStyleContext(typeName: "Switch", pseudoStates: ["on"]))
        let switchFocus = cascade.style(for: TCSSStyleContext(typeName: "Switch", pseudoStates: ["focus"]))
        let switchDisabled = cascade.style(for: TCSSStyleContext(typeName: "Switch", pseudoStates: ["disabled"]))
        baseDemo.toggleSwitch.offStyle = switchBase.terminalStyle.applied(to: baseDemo.toggleSwitch.offStyle)
        baseDemo.toggleSwitch.onStyle = switchOn.terminalStyle.applied(to: baseDemo.toggleSwitch.onStyle)
        baseDemo.toggleSwitch.focusedOffStyle = switchFocus.terminalStyle.applied(to: baseDemo.toggleSwitch.focusedOffStyle)
        baseDemo.toggleSwitch.focusedOnStyle = switchOn.terminalStyle.applied(to: baseDemo.toggleSwitch.focusedOnStyle)
        baseDemo.toggleSwitch.disabledStyle = switchDisabled.terminalStyle.applied(to: baseDemo.toggleSwitch.disabledStyle)
        baseDemo.toggleSwitch.frame = apply(switchBase.layout, to: baseDemo.toggleSwitch.frame)

        let select = cascade.style(for: TCSSStyleContext(typeName: "Select"))
        let selectFocus = cascade.style(for: TCSSStyleContext(typeName: "Select", pseudoStates: ["focus"]))
        let selectOpen = cascade.style(for: TCSSStyleContext(typeName: "Select", pseudoStates: ["open"]))
        let option = cascade.style(for: TCSSStyleContext(typeName: "Option"))
        let selectedOption = cascade.style(for: TCSSStyleContext(typeName: "Option", pseudoStates: ["selected"]))
        let disabledOption = cascade.style(for: TCSSStyleContext(typeName: "Option", pseudoStates: ["disabled"]))
        baseDemo.select.style = select.terminalStyle.applied(to: baseDemo.select.style)
        baseDemo.select.focusedStyle = selectFocus.terminalStyle.applied(to: baseDemo.select.focusedStyle)
        baseDemo.select.openStyle = selectOpen.terminalStyle.applied(to: baseDemo.select.openStyle)
        baseDemo.select.optionStyle = option.terminalStyle.applied(to: baseDemo.select.optionStyle)
        baseDemo.select.highlightedStyle = selectedOption.terminalStyle.applied(to: baseDemo.select.highlightedStyle)
        baseDemo.select.disabledStyle = disabledOption.terminalStyle.applied(to: baseDemo.select.disabledStyle)
        baseDemo.select.frame = apply(select.layout, to: baseDemo.select.frame)
    }

    private mutating func applyScrollableTCSS(_ cascade: TCSSCascade) {
        let scroll = cascade.style(for: TCSSStyleContext(typeName: "ScrollView"))
        let content = cascade.style(for: TCSSStyleContext(typeName: "ScrollContent"))
        let scrollbar = cascade.style(for: TCSSStyleContext(typeName: "ScrollBar"))
        let thumb = cascade.style(for: TCSSStyleContext(typeName: "ScrollBarThumb"))
        baseDemo.scrollView.fillStyle = scroll.terminalStyle.applied(to: baseDemo.scrollView.fillStyle)
        baseDemo.scrollView.contentStyle = content.terminalStyle.applied(to: baseDemo.scrollView.contentStyle)
        baseDemo.scrollView.scrollbarStyle = scrollbar.terminalStyle.applied(to: baseDemo.scrollView.scrollbarStyle)
        baseDemo.scrollView.thumbStyle = thumb.terminalStyle.applied(to: baseDemo.scrollView.thumbStyle)
        if let width = scrollbar.layout.width {
            baseDemo.scrollView.scrollbarWidth = max(1, width)
            sourceView.scrollbarWidth = max(1, width)
        }
        baseDemo.scrollView.frame = apply(scroll.layout, to: baseDemo.scrollView.frame)
        sourceView.fillStyle = scroll.terminalStyle.applied(to: sourceView.fillStyle)
        sourceView.scrollbarStyle = scrollbar.terminalStyle.applied(to: sourceView.scrollbarStyle)
        sourceView.thumbStyle = thumb.terminalStyle.applied(to: sourceView.thumbStyle)
    }

    private mutating func applyOverlayAndProgressTCSS(_ cascade: TCSSCascade) {
        let modal = cascade.style(for: TCSSStyleContext(typeName: "Modal"))
        let modalOverlay = cascade.style(for: TCSSStyleContext(typeName: "ModalOverlay"))
        let modalTitle = cascade.style(for: TCSSStyleContext(typeName: "ModalTitle"))
        let modalButton = cascade.style(for: TCSSStyleContext(typeName: "ModalButton"))
        let modalButtonFocus = cascade.style(for: TCSSStyleContext(typeName: "ModalButton", pseudoStates: ["focus"]))
        let modalButtonDisabled = cascade.style(for: TCSSStyleContext(typeName: "ModalButton", pseudoStates: ["disabled"]))
        baseDemo.modal.panelStyle = modal.terminalStyle.applied(to: baseDemo.modal.panelStyle)
        baseDemo.modal.overlayStyle = modalOverlay.terminalStyle.applied(to: baseDemo.modal.overlayStyle)
        baseDemo.modal.titleStyle = modalTitle.terminalStyle.applied(to: baseDemo.modal.titleStyle)
        baseDemo.modal.buttonStyle = modalButton.terminalStyle.applied(to: baseDemo.modal.buttonStyle)
        baseDemo.modal.focusedButtonStyle = modalButtonFocus.terminalStyle.applied(to: baseDemo.modal.focusedButtonStyle)
        baseDemo.modal.disabledButtonStyle = modalButtonDisabled.terminalStyle.applied(to: baseDemo.modal.disabledButtonStyle)
        baseDemo.modal.frame = apply(modal.layout, to: baseDemo.modal.frame)

        let progress = cascade.style(for: TCSSStyleContext(typeName: "ProgressBar"))
        let progressComplete = cascade.style(for: TCSSStyleContext(typeName: "ProgressBar", pseudoStates: ["complete"]))
        let progressPulse = cascade.style(for: TCSSStyleContext(typeName: "ProgressBar", pseudoStates: ["pulse"]))
        let progressText = cascade.style(for: TCSSStyleContext(typeName: "ProgressBarText"))
        baseDemo.progressBar.trackStyle = progress.terminalStyle.applied(to: baseDemo.progressBar.trackStyle)
        baseDemo.progressBar.completedStyle = progressComplete.terminalStyle.applied(to: baseDemo.progressBar.completedStyle)
        baseDemo.progressBar.pulseStyle = progressPulse.terminalStyle.applied(to: baseDemo.progressBar.pulseStyle)
        baseDemo.progressBar.textStyle = progressText.terminalStyle.applied(to: baseDemo.progressBar.textStyle)
        baseDemo.progressBar.frame = apply(progress.layout, to: baseDemo.progressBar.frame)
    }

    private mutating func applyDataControlsTCSS(_ cascade: TCSSCascade) {
        let log = cascade.style(for: TCSSStyleContext(typeName: "RichLog"))
        let logTitle = cascade.style(for: TCSSStyleContext(typeName: "RichLogTitle"))
        baseDemo.richLog.fillStyle = log.terminalStyle.applied(to: baseDemo.richLog.fillStyle)
        baseDemo.richLog.titleStyle = logTitle.terminalStyle.applied(to: baseDemo.richLog.titleStyle)
        baseDemo.richLog.frame = apply(log.layout, to: baseDemo.richLog.frame)

        let table = cascade.style(for: TCSSStyleContext(typeName: "DataTable"))
        let header = cascade.style(for: TCSSStyleContext(typeName: "Header"))
        let row = cascade.style(for: TCSSStyleContext(typeName: "Row"))
        let alternate = cascade.style(for: TCSSStyleContext(typeName: "Row", pseudoStates: ["alternate"]))
        let selected = cascade.style(for: TCSSStyleContext(typeName: "Row", pseudoStates: ["selected"]))
        let focusedSelected = cascade.style(for: TCSSStyleContext(typeName: "Row", pseudoStates: ["focus", "selected"]))
        baseDemo.dataTable.rowStyle = table.terminalStyle.applied(to: baseDemo.dataTable.rowStyle)
        baseDemo.dataTable.rowStyle = row.terminalStyle.applied(to: baseDemo.dataTable.rowStyle)
        baseDemo.dataTable.headerStyle = header.terminalStyle.applied(to: baseDemo.dataTable.headerStyle)
        baseDemo.dataTable.alternateRowStyle = alternate.terminalStyle.applied(to: baseDemo.dataTable.alternateRowStyle)
        baseDemo.dataTable.selectedRowStyle = selected.terminalStyle.applied(to: baseDemo.dataTable.selectedRowStyle)
        baseDemo.dataTable.focusedSelectedRowStyle = focusedSelected.terminalStyle.applied(to: baseDemo.dataTable.focusedSelectedRowStyle)
        baseDemo.dataTable.frame = apply(table.layout, to: baseDemo.dataTable.frame)

        let tree = cascade.style(for: TCSSStyleContext(typeName: "Tree"))
        let treeSelected = cascade.style(for: TCSSStyleContext(typeName: "Tree", pseudoStates: ["selected"]))
        let treeFocusedSelected = cascade.style(for: TCSSStyleContext(typeName: "Tree", pseudoStates: ["focus", "selected"]))
        let treeBranch = cascade.style(for: TCSSStyleContext(typeName: "TreeBranch"))
        let scrollbar = cascade.style(for: TCSSStyleContext(typeName: "ScrollBar"))
        let thumb = cascade.style(for: TCSSStyleContext(typeName: "ScrollBarThumb"))
        baseDemo.tree.fillStyle = tree.terminalStyle.applied(to: baseDemo.tree.fillStyle)
        baseDemo.tree.rowStyle = tree.terminalStyle.applied(to: baseDemo.tree.rowStyle)
        baseDemo.tree.selectedStyle = treeSelected.terminalStyle.applied(to: baseDemo.tree.selectedStyle)
        baseDemo.tree.focusedSelectedStyle = treeFocusedSelected.terminalStyle.applied(to: baseDemo.tree.focusedSelectedStyle)
        baseDemo.tree.branchStyle = treeBranch.terminalStyle.applied(to: baseDemo.tree.branchStyle)
        baseDemo.tree.scrollbarStyle = scrollbar.terminalStyle.applied(to: baseDemo.tree.scrollbarStyle)
        baseDemo.tree.thumbStyle = thumb.terminalStyle.applied(to: baseDemo.tree.thumbStyle)
        if let width = scrollbar.layout.width {
            baseDemo.tree.scrollbarWidth = max(1, width)
        }
        baseDemo.tree.frame = apply(tree.layout, to: baseDemo.tree.frame)
    }

    private mutating func applyCommandAndWorkerTCSS(_ cascade: TCSSCascade) {
        let command = cascade.style(for: TCSSStyleContext(typeName: "CommandPalette"))
        let commandTitle = cascade.style(for: TCSSStyleContext(typeName: "CommandPaletteTitle"))
        let commandInput = cascade.style(for: TCSSStyleContext(typeName: "CommandPaletteInput"))
        let commandItem = cascade.style(for: TCSSStyleContext(typeName: "CommandPaletteItem"))
        let commandSelected = cascade.style(for: TCSSStyleContext(typeName: "CommandPaletteItem", pseudoStates: ["selected"]))
        let commandDisabled = cascade.style(for: TCSSStyleContext(typeName: "CommandPaletteItem", pseudoStates: ["disabled"]))
        baseDemo.commandPalette.panelStyle = command.terminalStyle.applied(to: baseDemo.commandPalette.panelStyle)
        baseDemo.commandPalette.titleStyle = commandTitle.terminalStyle.applied(to: baseDemo.commandPalette.titleStyle)
        baseDemo.commandPalette.inputStyle = commandInput.terminalStyle.applied(to: baseDemo.commandPalette.inputStyle)
        baseDemo.commandPalette.itemStyle = commandItem.terminalStyle.applied(to: baseDemo.commandPalette.itemStyle)
        baseDemo.commandPalette.highlightedStyle = commandSelected.terminalStyle.applied(to: baseDemo.commandPalette.highlightedStyle)
        baseDemo.commandPalette.disabledStyle = commandDisabled.terminalStyle.applied(to: baseDemo.commandPalette.disabledStyle)
        baseDemo.commandPalette.frame = apply(command.layout, to: baseDemo.commandPalette.frame)

        let worker = cascade.style(for: TCSSStyleContext(typeName: "WorkerProgress"))
        let workerComplete = cascade.style(for: TCSSStyleContext(typeName: "WorkerProgress", pseudoStates: ["complete"]))
        let workerText = cascade.style(for: TCSSStyleContext(typeName: "WorkerProgressText"))
        baseDemo.workerProgressTrackStyle = worker.terminalStyle.applied(to: baseDemo.workerProgressTrackStyle)
        baseDemo.workerProgressCompletedStyle = workerComplete.terminalStyle.applied(to: baseDemo.workerProgressCompletedStyle)
        baseDemo.workerProgressTextStyle = workerText.terminalStyle.applied(to: baseDemo.workerProgressTextStyle)
    }

    private func apply(
        buttonStyle: TCSSStyle,
        focusedButtonStyle: TCSSStyle,
        disabledButtonStyle: TCSSStyle,
        to button: inout Button
    ) {
        button.style = buttonStyle.terminalStyle.applied(to: button.style)
        button.focusedStyle = focusedButtonStyle.terminalStyle.applied(to: button.focusedStyle)
        button.disabledStyle = disabledButtonStyle.terminalStyle.applied(to: button.disabledStyle)
        button.frame = apply(buttonStyle.layout, to: button.frame)
    }

    private func apply(_ layout: TCSSLayoutStyle, to frame: Rect) -> Rect {
        var next = frame
        if let width = layout.width {
            next.width = max(1, width)
        }
        if let height = layout.height {
            next.height = max(1, height)
        }
        if let minWidth = layout.minWidth {
            next.width = max(next.width, minWidth)
        }
        if let maxWidth = layout.maxWidth {
            next.width = min(next.width, max(1, maxWidth))
        }
        if let minHeight = layout.minHeight {
            next.height = max(next.height, minHeight)
        }
        if let maxHeight = layout.maxHeight {
            next.height = min(next.height, max(1, maxHeight))
        }
        return next
    }

    private func layoutPreferences(from layout: TCSSLayoutStyle, fallback: LayoutPreferences) -> LayoutPreferences {
        LayoutPreferences(
            width: layout.widthLength ?? fallback.width,
            height: layout.heightLength ?? fallback.height,
            minWidth: layout.minWidth ?? fallback.minWidth,
            minHeight: layout.minHeight ?? fallback.minHeight,
            maxWidth: layout.maxWidth ?? fallback.maxWidth,
            maxHeight: layout.maxHeight ?? fallback.maxHeight,
            margin: layout.margin.map { BoxEdges(top: $0.top, right: $0.right, bottom: $0.bottom, left: $0.left) } ?? fallback.margin
        )
    }

    private func textAlignment(from alignment: TCSSTextAlign) -> TextAlignment {
        switch alignment {
        case .left:
            .left
        case .center:
            .center
        case .right:
            .right
        }
    }

    private mutating func resetDemoStyles() {
        baseDemo.backgroundStyle = TerminalStyle(foreground: .brightWhite, background: .brightBlack)
        baseDemo.menuBar.resetStyles()
        baseDemo.button.frame = Rect(x: 2, y: 6, width: 12, height: 1)
        baseDemo.button.style = Button.defaultStyle
        baseDemo.button.focusedStyle = Button.defaultFocusedStyle
        baseDemo.button.disabledStyle = Button.defaultDisabledStyle
        baseDemo.demoButtons = MainViewContainer.defaultDemoButtons()
        baseDemo.demoLabels = MainViewContainer.defaultDemoLabels()
        baseDemo.textInput = TextInput(text: baseDemo.textInput.text, placeholder: "Type here", frame: Rect(x: 18, y: 6, width: 24, height: 1), cursorIndex: baseDemo.textInput.cursorIndex, isFocused: baseDemo.textInput.isFocused)
        baseDemo.checkbox = Checkbox("Enable feature", frame: Rect(x: 46, y: 6, width: 20, height: 1), isChecked: baseDemo.checkbox.isChecked, isFocused: baseDemo.checkbox.isFocused)
        baseDemo.toggleSwitch = Switch("Power", frame: Rect(x: 68, y: 6, width: 14, height: 1), isOn: baseDemo.toggleSwitch.isOn, isFocused: baseDemo.toggleSwitch.isFocused)
        baseDemo.select = Select(frame: Rect(x: 84, y: 6, width: 14, height: 1), options: [SelectOption("Alpha"), SelectOption("Beta"), SelectOption("Gamma")], selectedIndex: baseDemo.select.selectedIndex, isOpen: baseDemo.select.isOpen, isFocused: baseDemo.select.isFocused)
        baseDemo.scrollView.fillStyle = TerminalStyle(foreground: .brightWhite, background: .black)
        baseDemo.scrollView.scrollbarStyle = TerminalStyle(foreground: .white, background: .brightBlack)
        baseDemo.scrollView.thumbStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true)
        baseDemo.scrollView.contentStyle = TerminalStyle(foreground: .brightWhite, background: .black)
        baseDemo.scrollView.frame = Rect(x: 74, y: 14, width: 24, height: 5)
        baseDemo.modal = Modal(frame: Rect(x: 24, y: 8, width: 36, height: 8), title: "Swiftual", message: "Modal screen example", buttons: [ModalButton("OK"), ModalButton("Cancel")], selectedButtonIndex: baseDemo.modal.selectedButtonIndex, isPresented: baseDemo.modal.isPresented)
        baseDemo.progressBar = ProgressBar(frame: Rect(x: 52, y: 18, width: 20, height: 1), value: baseDemo.progressBar.value, label: "Load", pulseOffset: baseDemo.progressBar.pulseOffset)
        baseDemo.richLog.fillStyle = TerminalStyle(foreground: .brightWhite, background: .black)
        baseDemo.richLog.titleStyle = TerminalStyle(foreground: .black, background: .cyan, bold: true)
        baseDemo.richLog.frame = Rect(x: 2, y: 20, width: 96, height: 4)
        baseDemo.dataTable = DataTable(frame: Rect(x: 74, y: 8, width: 24, height: 5), columns: [DataTableColumn("Feature", width: 12), DataTableColumn("State", width: 10)], rows: [["Menu", "Ready"], ["Button", "Ready"], ["Modal", "Ready"], ["Log", "Ready"], ["Table", "New"]], selectedRowIndex: baseDemo.dataTable.selectedRowIndex, scrollOffset: baseDemo.dataTable.scrollOffset, isFocused: baseDemo.dataTable.isFocused)
        baseDemo.tree = Tree(frame: Rect(x: 100, y: 8, width: 30, height: 7), roots: baseDemo.tree.roots, selectedPath: baseDemo.tree.selectedPath, scrollOffset: baseDemo.tree.scrollOffset, isFocused: baseDemo.tree.isFocused)
        baseDemo.commandPalette = CommandPalette(frame: Rect(x: 38, y: 5, width: 44, height: 10), items: baseDemo.commandPalette.items, query: baseDemo.commandPalette.query, highlightedIndex: baseDemo.commandPalette.highlightedIndex, isPresented: baseDemo.commandPalette.isPresented)
        baseDemo.verticalFillStyle = TerminalStyle(foreground: .brightWhite, background: .black)
        baseDemo.verticalTitleStyle = TerminalStyle(foreground: .brightWhite, background: .black)
        baseDemo.verticalChildLabelStyle = TerminalStyle(foreground: .cyan, background: .black)
        baseDemo.verticalChildButtonStyle = Button.defaultStyle
        baseDemo.horizontalFillStyle = TerminalStyle(foreground: .brightWhite, background: .black)
        baseDemo.horizontalLabelStyle = TerminalStyle(foreground: .brightWhite, background: .black)
        baseDemo.horizontalButtonStyle = Button.defaultStyle
        baseDemo.horizontalFocusedButtonStyle = Button.defaultFocusedStyle
        baseDemo.workerProgressTrackStyle = TerminalStyle(foreground: .brightWhite, background: .black)
        baseDemo.workerProgressCompletedStyle = TerminalStyle(foreground: .brightWhite, background: .green, bold: true)
        baseDemo.workerProgressTextStyle = TerminalStyle(foreground: .brightWhite, bold: true)
        baseDemo.showcasePreferences = MainViewContainer.defaultShowcasePreferences
        baseDemo.introPanelPreferences = MainViewContainer.defaultIntroPanelPreferences
        baseDemo.formControlsPreferences = MainViewContainer.defaultFormControlsPreferences
        baseDemo.labelButtonPanelPreferences = MainViewContainer.defaultLabelButtonPanelPreferences
        baseDemo.containerPanelPreferences = MainViewContainer.defaultContainerPanelPreferences
        baseDemo.actionsPanelPreferences = MainViewContainer.defaultActionsPanelPreferences
        sourceView.fillStyle = TerminalStyle(foreground: .brightWhite, background: .black)
        sourceView.scrollbarStyle = TerminalStyle(foreground: .white, background: .brightBlack)
        sourceView.thumbStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true)
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
                    width: 18;
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

                TextInput,
                ScrollView,
                RichLog,
                DataTable,
                Tree {
                    background: black;
                    color: bright-white;
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
                Row:selected,
                CommandPaletteItem:selected {
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

                Header,
                RichLogTitle {
                    background: cyan;
                    color: black;
                }
                """
            ),
            TSSDemoStylesheet(
                fileName: "04-big.tcss",
                source: """
                /* Edge case: absurdly large element requests.
                   This stays big enough to stress flow without hiding the whole demo. */
                Button,
                Label,
                TextInput,
                Select,
                Checkbox,
                Switch {
                    width: 24;
                    height: 2;
                    padding: 1;
                }

                Vertical,
                Horizontal {
                    width: 46;
                    height: 8;
                }

                Modal {
                    width: 72;
                    height: 12;
                    padding: 2;
                }

                ProgressBar,
                WorkerProgress,
                CommandPalette,
                RichLog,
                DataTable,
                ScrollView,
                Tree {
                    width: 48;
                    height: 8;
                }
                """
            ),
            TSSDemoStylesheet(
                fileName: "05-small.tcss",
                source: """
                /* Edge case: tiny element requests.
                   Controls should clamp, crop, or degrade predictably. */
                Button,
                Label,
                TextInput,
                Select,
                Checkbox,
                Switch,
                ProgressBar,
                WorkerProgress {
                    width: 1;
                    height: 1;
                    padding: 0;
                }

                Modal,
                CommandPalette,
                RichLog,
                DataTable,
                Tree,
                Vertical,
                Horizontal,
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
                Button {
                    background: rgb(156, 39, 176);
                    color: rgb(255, 235, 59);
                    text-style: bold;
                }

                Button:focus {
                    background: rgb(0, 188, 212);
                    color: rgb(74, 20, 140);
                    text-style: bold;
                }

                Button:disabled {
                    background: rgb(96, 125, 139);
                    color: rgb(255, 193, 7);
                }

                Menu {
                    background: rgb(255, 64, 129);
                    color: rgb(0, 255, 213);
                }

                MenuItem {
                    background: rgb(0, 188, 212);
                    color: rgb(74, 20, 140);
                    text-style: bold;
                }

                MenuItem:disabled {
                    background: rgb(96, 125, 139);
                    color: rgb(255, 235, 59);
                }

                Label.centered,
                ProgressBar,
                ProgressBar:complete,
                WorkerProgress:complete,
                Header,
                RichLogTitle,
                CommandPaletteTitle,
                ModalTitle {
                    background: rgb(0, 188, 212);
                    color: rgb(255, 64, 129);
                }

                Checkbox:checked,
                Switch:on,
                Select:open,
                Option:selected,
                CommandPaletteItem:selected {
                    background: rgb(139, 195, 74);
                    color: rgb(74, 20, 140);
                    text-style: bold;
                }

                TextInput,
                ScrollView,
                Tree,
                RichLog,
                DataTable,
                CommandPalette,
                Modal,
                Vertical,
                Horizontal {
                    background: rgb(74, 20, 140);
                    color: rgb(255, 235, 59);
                }

                TextInput:focus,
                Cursor,
                ModalButton:focus {
                    background: rgb(255, 235, 59);
                    color: rgb(74, 20, 140);
                    text-style: bold;
                }

                ScrollBarThumb,
                ProgressBarText,
                WorkerProgressText,
                TreeBranch {
                    background: rgb(255, 64, 129);
                    color: rgb(0, 255, 213);
                }

                RichLog,
                Row:selected,
                Tree:selected {
                    background: rgb(255, 193, 7);
                    color: rgb(63, 81, 181);
                }
                """
            ),
            TSSDemoStylesheet(
                fileName: "07-percent-flow.tcss",
                source: """
                /* Feature set: percentage and fill-style outer layout.
                   The outer demo rows expand from the available pane instead of hard-coded cells. */
                Screen {
                    background: bright-black;
                    color: bright-white;
                }

                Showcase {
                    width: 100%;
                    height: 100%;
                }

                IntroPanel {
                    width: 100%;
                    height: auto;
                }

                FormRow {
                    width: 100%;
                    height: auto;
                }

                LabelButtonPanel {
                    width: 100%;
                    height: auto;
                }

                ContainerRow {
                    width: 100%;
                    height: 45%;
                    min-height: 5;
                }

                ActionsRow {
                    width: 100%;
                    height: auto;
                }

                SplitView {
                    divider-size: 1;
                    background: blue;
                }

                ScrollBar {
                    width: 2;
                }

                Vertical,
                Horizontal,
                DataTable,
                ScrollView,
                Tree,
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
