import Foundation

public struct MenuItem: Equatable, Sendable {
    public var title: String
    public var shortcut: String?
    public var isEnabled: Bool
    public var action: @Sendable () -> Void

    public init(
        _ title: String,
        shortcut: String? = nil,
        isEnabled: Bool = true,
        action: @escaping @Sendable () -> Void
    ) {
        self.title = title
        self.shortcut = shortcut
        self.isEnabled = isEnabled
        self.action = action
    }

    public static func == (lhs: MenuItem, rhs: MenuItem) -> Bool {
        lhs.title == rhs.title && lhs.shortcut == rhs.shortcut && lhs.isEnabled == rhs.isEnabled
    }
}

public struct Menu: Equatable, Sendable {
    public var title: String
    public var items: [MenuItem]

    public init(_ title: String, items: [MenuItem]) {
        self.title = title
        self.items = items
    }
}

public struct MenuBar: Equatable, Sendable {
    public var menus: [Menu]
    public var selectedMenuIndex: Int
    public var openedMenuIndex: Int?
    public var selectedItemIndex: Int
    public var barStyle: TerminalStyle
    public var selectedBarStyle: TerminalStyle
    public var menuStyle: TerminalStyle
    public var selectedItemStyle: TerminalStyle
    public var disabledItemStyle: TerminalStyle

    public init(
        menus: [Menu],
        barStyle: TerminalStyle = MenuBar.defaultBarStyle,
        selectedBarStyle: TerminalStyle = MenuBar.defaultSelectedBarStyle,
        menuStyle: TerminalStyle = MenuBar.defaultMenuStyle,
        selectedItemStyle: TerminalStyle = MenuBar.defaultSelectedItemStyle,
        disabledItemStyle: TerminalStyle = MenuBar.defaultDisabledItemStyle
    ) {
        self.menus = menus
        self.selectedMenuIndex = 0
        self.openedMenuIndex = nil
        self.selectedItemIndex = 0
        self.barStyle = barStyle
        self.selectedBarStyle = selectedBarStyle
        self.menuStyle = menuStyle
        self.selectedItemStyle = selectedItemStyle
        self.disabledItemStyle = disabledItemStyle
    }

    public static let defaultBarStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true)
    public static let defaultSelectedBarStyle = TerminalStyle(foreground: .blue, background: .brightWhite, bold: true)
    public static let defaultMenuStyle = TerminalStyle(foreground: .black, background: .brightBlack)
    public static let defaultSelectedItemStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true)
    public static let defaultDisabledItemStyle = TerminalStyle(foreground: .white, background: .brightBlack)

    public mutating func resetStyles() {
        barStyle = MenuBar.defaultBarStyle
        selectedBarStyle = MenuBar.defaultSelectedBarStyle
        menuStyle = MenuBar.defaultMenuStyle
        selectedItemStyle = MenuBar.defaultSelectedItemStyle
        disabledItemStyle = MenuBar.defaultDisabledItemStyle
    }

    public var isOpen: Bool {
        openedMenuIndex != nil
    }

    public mutating func handle(_ event: InputEvent) -> MenuCommand {
        switch event {
        case .key(.controlC), .key(.character("q")):
            return .quit
        case .key(.left):
            selectedMenuIndex = max(0, selectedMenuIndex - 1)
            if isOpen { openedMenuIndex = selectedMenuIndex }
            selectedItemIndex = 0
        case .key(.right), .key(.tab):
            selectedMenuIndex = min(max(0, menus.count - 1), selectedMenuIndex + 1)
            if isOpen { openedMenuIndex = selectedMenuIndex }
            selectedItemIndex = 0
        case .key(.down):
            if openedMenuIndex == nil {
                openedMenuIndex = selectedMenuIndex
                selectedItemIndex = firstEnabledItemIndex(in: selectedMenuIndex)
            } else {
                moveItem(delta: 1)
            }
        case .key(.up):
            if openedMenuIndex == nil {
                openedMenuIndex = selectedMenuIndex
                selectedItemIndex = lastEnabledItemIndex(in: selectedMenuIndex)
            } else {
                moveItem(delta: -1)
            }
        case .key(.enter), .key(.character(" ")):
            if openedMenuIndex == nil {
                openedMenuIndex = selectedMenuIndex
                selectedItemIndex = firstEnabledItemIndex(in: selectedMenuIndex)
            } else {
                return activateSelectedItem()
            }
        case .key(.escape):
            openedMenuIndex = nil
        case .mouse(let mouse):
            guard mouse.pressed, mouse.button == .left else { break }
            return handleMouseClick(at: mouse.location)
        default:
            break
        }

        return .none
    }

    public func render(in canvas: inout Canvas) {
        canvas.fill(rect: Rect(x: 0, y: 0, width: canvas.size.columns, height: 1), style: barStyle)

        var column = 0
        for index in menus.indices {
            let title = " \(menus[index].title) "
            let style = openedMenuIndex == index ? selectedBarStyle : barStyle
            canvas.drawText(title, at: Point(x: column, y: 0), style: style)
            column += title.count
        }

        if let openedMenuIndex {
            renderMenu(index: openedMenuIndex, in: &canvas)
        }
    }

    private func renderMenu(index: Int, in canvas: inout Canvas) {
        guard menus.indices.contains(index) else { return }
        let menu = menus[index]
        let originX = menuX(for: index)
        let width = max(12, menu.items.map { itemWidth($0) }.max() ?? 12)
        let height = max(1, menu.items.count)

        canvas.fill(rect: Rect(x: originX, y: 1, width: width, height: height), style: menuStyle)
        for itemIndex in menu.items.indices {
            let item = menu.items[itemIndex]
            let title = itemTitle(item, width: width)
            let style: TerminalStyle
            if itemIndex == selectedItemIndex {
                style = selectedItemStyle
            } else if item.isEnabled {
                style = menuStyle
            } else {
                style = disabledItemStyle
            }
            canvas.drawText(title, at: Point(x: originX, y: itemIndex + 1), style: style)
        }
    }

    private mutating func handleMouseClick(at point: Point) -> MenuCommand {
        if point.y == 0, let menuIndex = menuIndex(at: point.x) {
            selectedMenuIndex = menuIndex
            openedMenuIndex = menuIndex
            selectedItemIndex = firstEnabledItemIndex(in: menuIndex)
            return .none
        }

        if let openedMenuIndex, point.y > 0 {
            let originX = menuX(for: openedMenuIndex)
            let width = max(12, menus[openedMenuIndex].items.map { itemWidth($0) }.max() ?? 12)
            let itemIndex = point.y - 1
            if point.x >= originX,
               point.x < originX + width,
               menus[openedMenuIndex].items.indices.contains(itemIndex) {
                selectedItemIndex = itemIndex
                return activateSelectedItem()
            }
        }

        openedMenuIndex = nil
        return .none
    }

    private mutating func activateSelectedItem() -> MenuCommand {
        guard let openedMenuIndex,
              menus.indices.contains(openedMenuIndex),
              menus[openedMenuIndex].items.indices.contains(selectedItemIndex)
        else {
            return .none
        }

        let item = menus[openedMenuIndex].items[selectedItemIndex]
        guard item.isEnabled else { return .none }
        item.action()
        self.openedMenuIndex = nil
        return item.title.lowercased() == "quit" ? .quit : .activated(item.title)
    }

    private mutating func moveItem(delta: Int) {
        guard let openedMenuIndex, menus.indices.contains(openedMenuIndex) else { return }
        let items = menus[openedMenuIndex].items
        guard !items.isEmpty else { return }

        var next = selectedItemIndex
        for _ in items.indices {
            next = (next + delta + items.count) % items.count
            if items[next].isEnabled {
                selectedItemIndex = next
                return
            }
        }
    }

    private func menuIndex(at column: Int) -> Int? {
        var start = 0
        for index in menus.indices {
            let end = start + menus[index].title.count + 2
            if column >= start && column < end {
                return index
            }
            start = end
        }
        return nil
    }

    private func menuX(for index: Int) -> Int {
        menus.indices.prefix(index).reduce(0) { $0 + menus[$1].title.count + 2 }
    }

    private func itemWidth(_ item: MenuItem) -> Int {
        2 + item.title.count + 2 + (item.shortcut?.count ?? 0)
    }

    private func itemTitle(_ item: MenuItem, width: Int) -> String {
        let shortcut = item.shortcut ?? ""
        let middle = max(1, width - item.title.count - shortcut.count - 2)
        let text = " \(item.title)" + String(repeating: " ", count: middle) + shortcut
        return String(text.prefix(width)).padding(toLength: width, withPad: " ", startingAt: 0)
    }

    private func firstEnabledItemIndex(in menuIndex: Int) -> Int {
        guard menus.indices.contains(menuIndex) else { return 0 }
        return menus[menuIndex].items.firstIndex(where: \.isEnabled) ?? 0
    }

    private func lastEnabledItemIndex(in menuIndex: Int) -> Int {
        guard menus.indices.contains(menuIndex) else { return 0 }
        return menus[menuIndex].items.lastIndex(where: \.isEnabled) ?? 0
    }
}

public enum MenuCommand: Equatable, Sendable {
    case none
    case activated(String)
    case quit
}

public struct MainViewContainer: Equatable, Sendable {
    public var menuBar: MenuBar
    public var button: Button
    public var textInput: TextInput
    public var checkbox: Checkbox
    public var toggleSwitch: Switch
    public var select: Select
    public var scrollView: ScrollView
    public var modal: Modal
    public var progressBar: ProgressBar
    public var progressAnimationStartedAt: Date?
    public var progressAnimationDuration: TimeInterval
    public var richLog: RichLog
    public var dataTable: DataTable
    public var tree: Tree
    public var commandPalette: CommandPalette
    public var workerManager: WorkerManager
    public var splitClampSwitch: Switch
    public var logSplitDividerOffset: Int?
    public var logSplitIsDragging: Bool
    public var demoButtons: [Button]
    public var demoLabels: [Label]
    public var verticalFillStyle: TerminalStyle
    public var verticalTitleStyle: TerminalStyle
    public var verticalChildLabelStyle: TerminalStyle
    public var verticalChildButtonStyle: TerminalStyle
    public var horizontalFillStyle: TerminalStyle
    public var horizontalLabelStyle: TerminalStyle
    public var horizontalButtonStyle: TerminalStyle
    public var horizontalFocusedButtonStyle: TerminalStyle
    public var workerProgressTrackStyle: TerminalStyle
    public var workerProgressCompletedStyle: TerminalStyle
    public var workerProgressTextStyle: TerminalStyle
    public var backgroundStyle: TerminalStyle
    public var showcasePreferences: LayoutPreferences
    public var introPanelPreferences: LayoutPreferences
    public var formControlsPreferences: LayoutPreferences
    public var labelButtonPanelPreferences: LayoutPreferences
    public var containerPanelPreferences: LayoutPreferences
    public var actionsPanelPreferences: LayoutPreferences
    public var focusedControl: MainViewFocus

    public init(
        menuBar: MenuBar,
        button: Button = Button("Quit", frame: Rect(x: 2, y: 6, width: 12, height: 1)),
        textInput: TextInput = TextInput(text: "Swift", placeholder: "Type here", frame: Rect(x: 18, y: 6, width: 24, height: 1)),
        checkbox: Checkbox = Checkbox("Enable feature", frame: Rect(x: 46, y: 6, width: 20, height: 1), isChecked: true),
        toggleSwitch: Switch = Switch("Power", frame: Rect(x: 68, y: 6, width: 14, height: 1), isOn: true),
        select: Select = Select(frame: Rect(x: 84, y: 6, width: 14, height: 1), options: [SelectOption("Alpha"), SelectOption("Beta"), SelectOption("Gamma")]),
        scrollView: ScrollView = ScrollView(frame: Rect(x: 74, y: 14, width: 24, height: 5), content: (1...12).map { "Scroll row \($0)" }),
        modal: Modal = Modal(frame: Rect(x: 24, y: 8, width: 36, height: 8), title: "Swiftual", message: "Modal screen example", buttons: [ModalButton("OK"), ModalButton("Cancel")]),
        progressBar: ProgressBar = ProgressBar(frame: Rect(x: 52, y: 18, width: 20, height: 1), value: 0.65, label: "Load"),
        progressAnimationStartedAt: Date? = nil,
        progressAnimationDuration: TimeInterval = 5,
        richLog: RichLog = RichLog(
            frame: Rect(x: 2, y: 20, width: 96, height: 4),
            entries: [
                RichLogEntry("Ready: interact with controls to populate the log.", style: TerminalStyle(foreground: .brightWhite, background: .black))
            ]
        ),
        dataTable: DataTable = DataTable(
            frame: Rect(x: 74, y: 8, width: 24, height: 5),
            columns: [
                DataTableColumn("Feature", width: 12),
                DataTableColumn("State", width: 10)
            ],
            rows: [
                ["Menu", "Ready"],
                ["Button", "Ready"],
                ["Modal", "Ready"],
                ["Log", "Ready"],
                ["Table", "New"]
            ]
        ),
        tree: Tree = Tree(
            frame: Rect(x: 100, y: 8, width: 30, height: 7),
            roots: [
                TreeNode("Swiftual", children: [
                    TreeNode("Controls", children: [
                        TreeNode("Button"),
                        TreeNode("DataTable"),
                        TreeNode("Tree")
                    ]),
                    TreeNode("Runtime", isExpanded: false, children: [
                        TreeNode("Terminal"),
                        TreeNode("Events")
                    ])
                ])
            ]
        ),
        commandPalette: CommandPalette = CommandPalette(
            frame: Rect(x: 38, y: 5, width: 44, height: 10),
            items: [
                CommandPaletteItem("Quit", detail: "Exit the demo"),
                CommandPaletteItem("Show modal", detail: "Open the modal overlay"),
                CommandPaletteItem("Start worker", detail: "Run async progress"),
                CommandPaletteItem("Cancel worker", detail: "Stop async progress"),
                CommandPaletteItem("Focus tree", detail: "Move focus to tree")
            ]
        ),
        workerManager: WorkerManager = WorkerManager(),
        splitClampSwitch: Switch = Switch("Clamp log", frame: Rect(x: 116, y: 16, width: 18, height: 1), isOn: false),
        demoButtons: [Button] = MainViewContainer.defaultDemoButtons(),
        demoLabels: [Label] = MainViewContainer.defaultDemoLabels(),
        verticalFillStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        verticalTitleStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        verticalChildLabelStyle: TerminalStyle = TerminalStyle(foreground: .cyan, background: .black),
        verticalChildButtonStyle: TerminalStyle = Button.defaultStyle,
        horizontalFillStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        horizontalLabelStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        horizontalButtonStyle: TerminalStyle = Button.defaultStyle,
        horizontalFocusedButtonStyle: TerminalStyle = Button.defaultFocusedStyle,
        workerProgressTrackStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        workerProgressCompletedStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .green, bold: true),
        workerProgressTextStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, bold: true),
        backgroundStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .brightBlack),
        showcasePreferences: LayoutPreferences = MainViewContainer.defaultShowcasePreferences,
        introPanelPreferences: LayoutPreferences = MainViewContainer.defaultIntroPanelPreferences,
        formControlsPreferences: LayoutPreferences = MainViewContainer.defaultFormControlsPreferences,
        labelButtonPanelPreferences: LayoutPreferences = MainViewContainer.defaultLabelButtonPanelPreferences,
        containerPanelPreferences: LayoutPreferences = MainViewContainer.defaultContainerPanelPreferences,
        actionsPanelPreferences: LayoutPreferences = MainViewContainer.defaultActionsPanelPreferences
    ) {
        self.menuBar = menuBar
        self.button = button
        self.textInput = textInput
        self.checkbox = checkbox
        self.toggleSwitch = toggleSwitch
        self.select = select
        self.scrollView = scrollView
        self.modal = modal
        self.progressBar = progressBar
        self.progressAnimationStartedAt = progressAnimationStartedAt
        self.progressAnimationDuration = progressAnimationDuration
        self.richLog = richLog
        self.dataTable = dataTable
        self.tree = tree
        self.commandPalette = commandPalette
        self.workerManager = workerManager
        self.splitClampSwitch = splitClampSwitch
        self.logSplitDividerOffset = nil
        self.logSplitIsDragging = false
        self.demoButtons = demoButtons
        self.demoLabels = demoLabels
        self.verticalFillStyle = verticalFillStyle
        self.verticalTitleStyle = verticalTitleStyle
        self.verticalChildLabelStyle = verticalChildLabelStyle
        self.verticalChildButtonStyle = verticalChildButtonStyle
        self.horizontalFillStyle = horizontalFillStyle
        self.horizontalLabelStyle = horizontalLabelStyle
        self.horizontalButtonStyle = horizontalButtonStyle
        self.horizontalFocusedButtonStyle = horizontalFocusedButtonStyle
        self.workerProgressTrackStyle = workerProgressTrackStyle
        self.workerProgressCompletedStyle = workerProgressCompletedStyle
        self.workerProgressTextStyle = workerProgressTextStyle
        self.backgroundStyle = backgroundStyle
        self.showcasePreferences = showcasePreferences
        self.introPanelPreferences = introPanelPreferences
        self.formControlsPreferences = formControlsPreferences
        self.labelButtonPanelPreferences = labelButtonPanelPreferences
        self.containerPanelPreferences = containerPanelPreferences
        self.actionsPanelPreferences = actionsPanelPreferences
        self.focusedControl = .menuBar
    }

    public mutating func handle(_ event: InputEvent, terminalSize: TerminalSize = TerminalSize(columns: 140, rows: 24)) -> MenuCommand {
        applyShowcaseLayout(for: terminalSize)

        if commandPalette.isPresented {
            return handleCommandPalette(commandPalette.handle(event))
        }

        if modal.isPresented {
            logModalCommand(modal.handle(event))
            return .none
        }

        if event == .key(.controlP) {
            presentCommandPalette()
            return .none
        }

        if event == .key(.tab), !menuBar.isOpen {
            focusedControl = focusedControl.next
            return .none
        }

        if case .mouse(let mouse) = event, mouse.pressed, mouse.button == .left, mouse.location.y == 0 || menuBar.isOpen {
            focusedControl = .menuBar
            let command = menuBar.handle(event)
            logMenuCommand(command)
            return command
        }

        if handleLogSplitDrag(event, terminalSize: terminalSize) {
            return .none
        }

        if case .mouse(let mouse) = event, mouse.pressed, mouse.button == .left, button.frame.contains(mouse.location) {
            focusedControl = .button
            let command = button.handle(event)
            logButtonCommand(command)
            return command == .activated("Quit") ? .quit : .none
        }

        if case .mouse(let mouse) = event, mouse.pressed, mouse.button == .left, textInput.frame.contains(mouse.location) {
            focusedControl = .textInput
            logTextInputCommand(textInput.handle(event))
            return .none
        }

        if case .mouse(let mouse) = event, mouse.pressed, mouse.button == .left, checkbox.frame.contains(mouse.location) {
            focusedControl = .checkbox
            logCheckboxCommand(checkbox.handle(event))
            return .none
        }

        if case .mouse(let mouse) = event, mouse.pressed, mouse.button == .left, toggleSwitch.frame.contains(mouse.location) {
            focusedControl = .switch
            logSwitchCommand(toggleSwitch.handle(event))
            return .none
        }

        if case .mouse(let mouse) = event, mouse.pressed, mouse.button == .left {
            if select.frame.contains(mouse.location) || select.isOpen {
                focusedControl = .select
                logSelectCommand(select.handle(event))
                return .none
            }
        }

        if case .mouse(let mouse) = event, scrollView.frame.contains(mouse.location) {
            focusedControl = .scrollView
            logScrollViewCommand(scrollView.handle(event))
            return .none
        }

        if case .mouse(let mouse) = event, dataTable.frame.contains(mouse.location) {
            focusedControl = .dataTable
            logDataTableCommand(dataTable.handle(event))
            return .none
        }

        if case .mouse(let mouse) = event, tree.frame.contains(mouse.location) {
            focusedControl = .tree
            logTreeCommand(tree.handle(event))
            return .none
        }

        let layout = showcaseLayout(for: terminalSize)
        let commandButton = Button("Commands", frame: layout.commandButtonFrame)
        if case .mouse(let mouse) = event, mouse.pressed, mouse.button == .left, commandButton.frame.contains(mouse.location) {
            focusedControl = .commandPaletteButton
            presentCommandPalette()
            return .none
        }

        if case .mouse(let mouse) = event, mouse.pressed, mouse.button == .left, splitClampSwitch.frame.contains(mouse.location) {
            focusedControl = .splitClampSwitch
            logSplitClampSwitchCommand(splitClampSwitch.handle(event))
            return .none
        }

        let workerButton = Button(workerButtonTitle, frame: layout.workerButtonFrame)
        if case .mouse(let mouse) = event, mouse.pressed, mouse.button == .left, workerButton.frame.contains(mouse.location) {
            focusedControl = .workerButton
            toggleWorker()
            return .none
        }

        let modalButton = Button("Show modal", frame: layout.modalButtonFrame)
        if case .mouse(let mouse) = event, mouse.pressed, mouse.button == .left, modalButton.frame.contains(mouse.location) {
            focusedControl = .modalButton
            modal.present()
            richLog.append("Modal opened.", style: TerminalStyle(foreground: .cyan, background: .black))
            return .none
        }

        let progressButton = Button("Animate", frame: layout.progressButtonFrame)
        if case .mouse(let mouse) = event, mouse.pressed, mouse.button == .left, progressButton.frame.contains(mouse.location) {
            focusedControl = .progressButton
            startProgressAnimation()
            return .none
        }

        switch focusedControl {
        case .menuBar:
            let command = menuBar.handle(event)
            logMenuCommand(command)
            return command
        case .button:
            button.isFocused = true
            switch button.handle(event) {
            case .activated("Quit"):
                richLog.append("Button activated: Quit.", style: TerminalStyle(foreground: .yellow, background: .black, bold: true))
                return .quit
            case .activated(let title):
                richLog.append("Button activated: \(title).", style: TerminalStyle(foreground: .yellow, background: .black, bold: true))
                return .none
            case .none:
                if case .mouse = event {
                    focusedControl = .menuBar
                    let command = menuBar.handle(event)
                    logMenuCommand(command)
                    return command
                }
                return .none
            }
        case .textInput:
            textInput.isFocused = true
            logTextInputCommand(textInput.handle(event))
            return .none
        case .checkbox:
            checkbox.isFocused = true
            logCheckboxCommand(checkbox.handle(event))
            return .none
        case .switch:
            toggleSwitch.isFocused = true
            logSwitchCommand(toggleSwitch.handle(event))
            return .none
        case .select:
            select.isFocused = true
            logSelectCommand(select.handle(event))
            return .none
        case .scrollView:
            scrollView.isFocused = true
            logScrollViewCommand(scrollView.handle(event))
            return .none
        case .modalButton:
            if event == .key(.enter) || event == .key(.character(" ")) {
                modal.present()
                richLog.append("Modal opened.", style: TerminalStyle(foreground: .cyan, background: .black))
            }
            return .none
        case .progressButton:
            if event == .key(.enter) || event == .key(.character(" ")) {
                startProgressAnimation()
            }
            return .none
        case .dataTable:
            dataTable.isFocused = true
            logDataTableCommand(dataTable.handle(event))
            return .none
        case .tree:
            tree.isFocused = true
            logTreeCommand(tree.handle(event))
            return .none
        case .commandPaletteButton:
            if event == .key(.enter) || event == .key(.character(" ")) {
                presentCommandPalette()
            }
            return .none
        case .splitClampSwitch:
            splitClampSwitch.isFocused = true
            logSplitClampSwitchCommand(splitClampSwitch.handle(event))
            return .none
        case .workerButton:
            if event == .key(.enter) || event == .key(.character(" ")) {
                toggleWorker()
            }
            return .none
        }
    }

    public mutating func startProgressAnimation(now: Date = Date()) {
        progressAnimationStartedAt = now
        progressBar.value = 0
        richLog.append("Progress animation started: 0% to 100%.", style: TerminalStyle(foreground: .green, background: .black, bold: true))
    }

    public mutating func updateProgressAnimation(now: Date = Date()) {
        guard let progressAnimationStartedAt else { return }
        let duration = max(0.001, progressAnimationDuration)
        let elapsed = now.timeIntervalSince(progressAnimationStartedAt)
        let fraction = min(1, max(0, elapsed / duration))
        progressBar.value = fraction
        if fraction >= 1 {
            self.progressAnimationStartedAt = nil
            richLog.append("Progress animation finished: 100%.", style: TerminalStyle(foreground: .green, background: .black, bold: true))
        }
    }

    public mutating func updateWorkerEvents() {
        for event in workerManager.drainEvents() {
            let style: TerminalStyle
            switch event.state {
            case .running:
                style = TerminalStyle(foreground: .brightWhite, background: .black)
            case .completed:
                style = TerminalStyle(foreground: .green, background: .black, bold: true)
            case .cancelled:
                style = TerminalStyle(foreground: .yellow, background: .black, bold: true)
            case .failed:
                style = TerminalStyle(foreground: .red, background: .black, bold: true)
            case .idle:
                style = TerminalStyle(foreground: .white, background: .black)
            }
            richLog.append(event.message, style: style)
        }
    }

    private var workerButtonTitle: String {
        workerManager.state == .running ? "Cancel job" : "Run worker"
    }

    private mutating func toggleWorker() {
        if workerManager.state == .running {
            workerManager.cancel()
        } else {
            workerManager.startDemoTask()
        }
        updateWorkerEvents()
    }

    private mutating func presentCommandPalette() {
        commandPalette.present()
        focusedControl = .commandPaletteButton
        richLog.append("Command palette opened.", style: TerminalStyle(foreground: .cyan, background: .black))
    }

    private mutating func handleCommandPalette(_ command: CommandPaletteCommand) -> MenuCommand {
        logCommandPaletteCommand(command)
        guard case .selected(let title) = command else { return .none }
        switch title {
        case "Quit":
            return .quit
        case "Show modal":
            modal.present()
        case "Start worker":
            workerManager.startDemoTask()
            updateWorkerEvents()
        case "Cancel worker":
            workerManager.cancel()
            updateWorkerEvents()
        case "Focus tree":
            focusedControl = .tree
        default:
            break
        }
        return .none
    }

    private mutating func logMenuCommand(_ command: MenuCommand) {
        switch command {
        case .none:
            if menuBar.isOpen, let index = menuBar.openedMenuIndex, menuBar.menus.indices.contains(index) {
                richLog.append("Menu opened: \(menuBar.menus[index].title).", style: TerminalStyle(foreground: .cyan, background: .black))
            }
        case .activated(let title):
            richLog.append("Menu selected: \(title).", style: TerminalStyle(foreground: .yellow, background: .black, bold: true))
        case .quit:
            richLog.append("Menu selected: Quit.", style: TerminalStyle(foreground: .yellow, background: .black, bold: true))
        }
    }

    private mutating func logButtonCommand(_ command: ButtonCommand) {
        guard case .activated(let title) = command else { return }
        richLog.append("Button activated: \(title).", style: TerminalStyle(foreground: .yellow, background: .black, bold: true))
    }

    private mutating func logTextInputCommand(_ command: TextInputCommand) {
        switch command {
        case .focused:
            richLog.append("Text input focused.", style: TerminalStyle(foreground: .cyan, background: .black))
        case .changed(let text):
            richLog.append("Text input changed: \(text).", style: TerminalStyle(foreground: .brightWhite, background: .black))
        case .cursorMoved(let index):
            richLog.append("Text input cursor moved: \(index).", style: TerminalStyle(foreground: .white, background: .black))
        case .submitted(let text):
            richLog.append("Text input submitted: \(text).", style: TerminalStyle(foreground: .green, background: .black, bold: true))
        case .none:
            break
        }
    }

    private mutating func logCheckboxCommand(_ command: CheckboxCommand) {
        guard case .changed(let isChecked) = command else { return }
        richLog.append("Checkbox changed: \(isChecked ? "checked" : "unchecked").", style: TerminalStyle(foreground: .green, background: .black))
    }

    private mutating func logSwitchCommand(_ command: SwitchCommand) {
        guard case .changed(let isOn) = command else { return }
        richLog.append("Switch changed: \(isOn ? "on" : "off").", style: TerminalStyle(foreground: .green, background: .black))
    }

    private mutating func logSplitClampSwitchCommand(_ command: SwitchCommand) {
        guard case .changed(let isOn) = command else { return }
        logSplitDividerOffset = nil
        logSplitIsDragging = false
        richLog.append("Log split clamp changed: \(isOn ? "clamped" : "unclamped").", style: TerminalStyle(foreground: .green, background: .black))
    }

    private mutating func logSelectCommand(_ command: SelectCommand) {
        switch command {
        case .opened:
            richLog.append("Select opened.", style: TerminalStyle(foreground: .cyan, background: .black))
        case .closed:
            richLog.append("Select closed.", style: TerminalStyle(foreground: .white, background: .black))
        case .highlighted(let index):
            richLog.append("Select highlighted option \(index).", style: TerminalStyle(foreground: .white, background: .black))
        case .changed(_, let title):
            richLog.append("Select picked: \(title).", style: TerminalStyle(foreground: .green, background: .black, bold: true))
        case .none:
            break
        }
    }

    private mutating func logScrollViewCommand(_ command: ScrollViewCommand) {
        switch command {
        case .focused:
            richLog.append("Scroll view focused.", style: TerminalStyle(foreground: .cyan, background: .black))
        case .scrolled(let offset):
            richLog.append("Scroll view moved to offset \(offset).", style: TerminalStyle(foreground: .white, background: .black))
        case .none:
            break
        }
    }

    private mutating func logModalCommand(_ command: ModalCommand) {
        switch command {
        case .dismissed:
            richLog.append("Modal dismissed.", style: TerminalStyle(foreground: .white, background: .black))
        case .highlighted(let index):
            richLog.append("Modal highlighted option \(index).", style: TerminalStyle(foreground: .white, background: .black))
        case .selected(_, let title):
            richLog.append("Modal picked option: \(title).", style: TerminalStyle(foreground: .green, background: .black, bold: true))
        case .none:
            break
        }
    }

    private mutating func logDataTableCommand(_ command: DataTableCommand) {
        switch command {
        case .focused:
            richLog.append("Data table focused.", style: TerminalStyle(foreground: .cyan, background: .black))
        case .selected(let index, let row):
            richLog.append("Data table selected row \(index): \(row.joined(separator: " / ")).", style: TerminalStyle(foreground: .white, background: .black))
        case .activated(let index, let row):
            richLog.append("Data table activated row \(index): \(row.joined(separator: " / ")).", style: TerminalStyle(foreground: .green, background: .black, bold: true))
        case .none:
            break
        }
    }

    private mutating func logTreeCommand(_ command: TreeCommand) {
        switch command {
        case .focused:
            richLog.append("Tree focused.", style: TerminalStyle(foreground: .cyan, background: .black))
        case .selected(let row):
            richLog.append("Tree selected: \(row.title).", style: TerminalStyle(foreground: .white, background: .black))
        case .expanded(let row):
            richLog.append("Tree expanded: \(row.title).", style: TerminalStyle(foreground: .green, background: .black, bold: true))
        case .collapsed(let row):
            richLog.append("Tree collapsed: \(row.title).", style: TerminalStyle(foreground: .yellow, background: .black, bold: true))
        case .activated(let row):
            richLog.append("Tree activated: \(row.title).", style: TerminalStyle(foreground: .green, background: .black, bold: true))
        case .scrolled(let offset):
            richLog.append("Tree moved to offset \(offset).", style: TerminalStyle(foreground: .white, background: .black))
        case .none:
            break
        }
    }

    private mutating func logCommandPaletteCommand(_ command: CommandPaletteCommand) {
        switch command {
        case .dismissed:
            richLog.append("Command palette dismissed.", style: TerminalStyle(foreground: .white, background: .black))
        case .highlighted(let index):
            richLog.append("Command palette highlighted option \(index).", style: TerminalStyle(foreground: .white, background: .black))
        case .queryChanged(let query):
            richLog.append("Command palette query: \(query).", style: TerminalStyle(foreground: .white, background: .black))
        case .selected(let title):
            richLog.append("Command palette selected: \(title).", style: TerminalStyle(foreground: .green, background: .black, bold: true))
        case .none:
            break
        }
    }

    public func render(size: TerminalSize) -> Canvas {
        var canvas = Canvas(size: size, fill: Cell(" ", style: backgroundStyle))
        canvas.fill(rect: Rect(x: 0, y: 1, width: size.columns, height: max(0, size.rows - 1)), style: backgroundStyle)
        let logSplit = logSplitView(for: size)
        let baseShowcaseFrame = Rect(
            x: logSplit.topFrame.x + 2,
            y: logSplit.topFrame.y + 1,
            width: max(0, logSplit.topFrame.width - 4),
            height: max(0, logSplit.topFrame.height - 2)
        )
        let showcaseFrame = rect(
            from: showcasePreferences,
            defaultFrame: baseShowcaseFrame,
            parentFrame: baseShowcaseFrame
        )

        let vertical = Vertical(
            frame: Rect(x: 0, y: 0, width: 30, height: 5),
            spacing: 1,
            fillStyle: verticalFillStyle,
            border: .single(style: verticalTitleStyle),
            borderTitle: "Vertical",
            borderSubtitle: "Stack",
            children: [
                AnyCanvasRenderable(Label("Child label", frame: Rect(x: 0, y: 0, width: 28, height: 1), style: verticalChildLabelStyle)),
                AnyCanvasRenderable(Button("Child button", frame: Rect(x: 0, y: 0, width: 16, height: 1), style: verticalChildButtonStyle))
            ]
        )

        let horizontal = Horizontal(
            frame: Rect(x: 0, y: 0, width: 38, height: 3),
            spacing: 2,
            fillStyle: horizontalFillStyle,
            border: .single(style: horizontalLabelStyle),
            borderTitle: "Horizontal",
            borderSubtitle: "Row",
            children: [
                AnyCanvasRenderable(Label("Horizontal", frame: Rect(x: 0, y: 0, width: 12, height: 1), style: horizontalLabelStyle)),
                AnyCanvasRenderable(Button("One", frame: Rect(x: 0, y: 0, width: 8, height: 1), style: horizontalButtonStyle)),
                AnyCanvasRenderable(Button("Two", frame: Rect(x: 0, y: 0, width: 8, height: 1), isFocused: true, style: horizontalButtonStyle, focusedStyle: horizontalFocusedButtonStyle))
            ]
        )

        var button = button
        button.isFocused = focusedControl == .button
        var textInput = textInput
        textInput.isFocused = focusedControl == .textInput
        var checkbox = checkbox
        checkbox.isFocused = focusedControl == .checkbox
        var toggleSwitch = toggleSwitch
        toggleSwitch.isFocused = focusedControl == .switch
        var select = select
        select.isFocused = focusedControl == .select
        var scrollView = scrollView
        scrollView.isFocused = focusedControl == .scrollView
        var dataTable = dataTable
        dataTable.isFocused = focusedControl == .dataTable
        var tree = tree
        tree.isFocused = focusedControl == .tree
        var splitClampSwitch = splitClampSwitch
        splitClampSwitch.isFocused = focusedControl == .splitClampSwitch
        let modalButton = Button("Show modal", frame: Rect(x: 0, y: 0, width: 14, height: 1), isFocused: focusedControl == .modalButton)
        let progressButton = Button("Animate", frame: Rect(x: 0, y: 0, width: 12, height: 1), isFocused: focusedControl == .progressButton)
        let commandButton = Button("Commands", frame: Rect(x: 0, y: 0, width: 14, height: 1), isFocused: focusedControl == .commandPaletteButton)
        let workerButton = Button(workerButtonTitle, frame: Rect(x: 0, y: 0, width: 14, height: 1), isFocused: focusedControl == .workerButton)
        let workerProgress = ProgressBar(
            frame: Rect(x: 100, y: 20, width: 30, height: 1),
            value: workerManager.state == .idle ? 0 : workerManager.progress,
            label: "Worker",
            trackStyle: workerProgressTrackStyle,
            completedStyle: workerProgressCompletedStyle,
            textStyle: workerProgressTextStyle
        )
        let introPanel = FlowContainer(
            frame: Rect(x: 0, y: 0, width: showcaseFrame.width, height: 3),
            axis: .vertical,
            spacing: FlowSpacing(main: 1),
            children: [
                FlowChild(Label("Swiftual demo", frame: Rect(x: 0, y: 0, width: max(0, showcaseFrame.width), height: 1), style: backgroundStyle)),
                FlowChild(Label("Use mouse or keyboard: arrows, Enter, Escape. File > Quit exits.", frame: Rect(x: 0, y: 0, width: max(0, showcaseFrame.width), height: 1), style: backgroundStyle))
            ]
        )
        let formControls = FlowContainer(
            frame: Rect(x: 0, y: 0, width: showcaseFrame.width, height: max(1, [button.frame.height, textInput.frame.height, checkbox.frame.height, toggleSwitch.frame.height, select.frame.height].max() ?? 1)),
            axis: .horizontal,
            spacing: FlowSpacing(main: 2),
            children: [
                FlowChild(button),
                FlowChild(textInput),
                FlowChild(checkbox),
                FlowChild(toggleSwitch),
                FlowChild(select)
            ]
        )
        let labelRow = FlowContainer(
            frame: Rect(x: 0, y: 0, width: showcaseFrame.width, height: max(1, demoLabels.map(\.frame.height).max() ?? 1)),
            axis: .horizontal,
            spacing: FlowSpacing(main: 2),
            children: demoLabels.map { FlowChild($0) }
        )
        let buttonRow = FlowContainer(
            frame: Rect(x: 0, y: 0, width: showcaseFrame.width, height: max(1, demoButtons.map(\.frame.height).max() ?? 1)),
            axis: .horizontal,
            spacing: FlowSpacing(main: 2),
            children: demoButtons.map { FlowChild($0) }
        )
        let labelButtonPanel = FlowContainer(
            frame: Rect(x: 0, y: 0, width: showcaseFrame.width, height: 3),
            axis: .vertical,
            spacing: FlowSpacing(main: 1),
            children: [
                FlowChild(labelRow, preferences: LayoutPreferences(width: .fill, height: .auto)),
                FlowChild(buttonRow, preferences: LayoutPreferences(width: .fill, height: .auto))
            ]
        )
        let containerPanel = FlowContainer(
            frame: Rect(x: 0, y: 0, width: showcaseFrame.width, height: 5),
            axis: .horizontal,
            spacing: FlowSpacing(main: 3),
            overflow: Overflow(x: .hidden, y: .hidden),
            children: [
                FlowChild(vertical),
                FlowChild(horizontal),
                FlowChild(dataTable),
                FlowChild(scrollView),
                FlowChild(tree)
            ]
        )
        let progressPanel = FlowContainer(
            frame: Rect(x: 0, y: 0, width: max(progressBar.frame.width, progressButton.frame.width), height: 3),
            axis: .vertical,
            spacing: FlowSpacing(main: 1),
            alignment: FlowAlignment(horizontal: .center, vertical: .top),
            children: [
                FlowChild(progressBar),
                FlowChild(progressButton)
            ]
        )
        let workerPanel = FlowContainer(
            frame: Rect(x: 0, y: 0, width: max(workerProgress.frame.width, workerButton.frame.width), height: 3),
            axis: .vertical,
            spacing: FlowSpacing(main: 1),
            children: [
                FlowChild(workerButton),
                FlowChild(workerProgress)
            ]
        )
        let actionsPanel = FlowContainer(
            frame: Rect(x: 0, y: 0, width: showcaseFrame.width, height: 3),
            axis: .horizontal,
            spacing: FlowSpacing(main: 3),
            children: [
                FlowChild(modalButton),
                FlowChild(progressPanel),
                FlowChild(commandButton),
                FlowChild(splitClampSwitch),
                FlowChild(workerPanel)
            ]
        )
        FlowContainer(
            frame: showcaseFrame,
            axis: .vertical,
            spacing: FlowSpacing(main: 1),
            overflow: .hidden,
            children: [
                FlowChild(introPanel, preferences: introPanelPreferences),
                FlowChild(formControls, preferences: formControlsPreferences),
                FlowChild(labelButtonPanel, preferences: labelButtonPanelPreferences),
                FlowChild(containerPanel, preferences: containerPanelPreferences),
                FlowChild(actionsPanel, preferences: actionsPanelPreferences)
            ]
        ).render(in: &canvas)

        logSplit.render(in: &canvas)
        var richLog = richLog
        richLog.frame = richLogFrame(in: logSplit.bottomFrame)
        richLog.render(in: &canvas)
        modal.render(in: &canvas)
        commandPalette.render(in: &canvas)
        let menuBar = menuBar
        menuBar.render(in: &canvas)
        return canvas
    }

    private func logSplitView(for size: TerminalSize) -> VerticalSplitView {
        let frame = Rect(x: 0, y: 1, width: size.columns, height: max(0, size.rows - 1))
        let preferredOffset = max(21, frame.height - 8)
        return VerticalSplitView(
            frame: frame,
            dividerOffset: logSplitDividerOffset ?? preferredOffset,
            minTop: 8,
            minBottom: 1,
            isClamped: splitClampSwitch.isOn,
            isDragging: logSplitIsDragging
        )
    }

    private mutating func handleLogSplitDrag(_ event: InputEvent, terminalSize: TerminalSize) -> Bool {
        var split = logSplitView(for: terminalSize)
        let command = split.handle(event)
        guard command != .none else { return false }

        logSplitDividerOffset = split.dividerOffset
        logSplitIsDragging = split.isDragging
        return true
    }

    private func richLogFrame(in bottomPane: Rect) -> Rect {
        Rect(
            x: bottomPane.x + 2,
            y: bottomPane.y,
            width: max(0, bottomPane.width - 4),
            height: bottomPane.height
        )
    }

    private mutating func applyShowcaseLayout(for size: TerminalSize) {
        let layout = showcaseLayout(for: size)
        button.frame = layout.buttonFrame
        textInput.frame = layout.textInputFrame
        checkbox.frame = layout.checkboxFrame
        toggleSwitch.frame = layout.switchFrame
        select.frame = layout.selectFrame
        for index in demoLabels.indices where layout.labelFrames.indices.contains(index) {
            demoLabels[index].frame = layout.labelFrames[index]
        }
        for index in demoButtons.indices where layout.demoButtonFrames.indices.contains(index) {
            demoButtons[index].frame = layout.demoButtonFrames[index]
        }
        dataTable.frame = layout.dataTableFrame
        scrollView.frame = layout.scrollViewFrame
        tree.frame = layout.treeFrame
        progressBar.frame = layout.progressBarFrame
        splitClampSwitch.frame = layout.splitClampSwitchFrame
    }

    private func showcaseLayout(for size: TerminalSize) -> ShowcaseLayout {
        let logSplit = logSplitView(for: size)
        let baseShowcaseFrame = Rect(
            x: logSplit.topFrame.x + 2,
            y: logSplit.topFrame.y + 1,
            width: max(0, logSplit.topFrame.width - 4),
            height: max(0, logSplit.topFrame.height - 2)
        )
        let showcaseFrame = rect(
            from: showcasePreferences,
            defaultFrame: baseShowcaseFrame,
            parentFrame: baseShowcaseFrame
        )

        let formHeight = max(1, [button.frame.height, textInput.frame.height, checkbox.frame.height, toggleSwitch.frame.height, select.frame.height].max() ?? 1)
        let labelHeight = max(1, demoLabels.map(\.frame.height).max() ?? 1)
        let demoButtonHeight = max(1, demoButtons.map(\.frame.height).max() ?? 1)

        let introPanel = FlowContainer(frame: Rect(x: 0, y: 0, width: showcaseFrame.width, height: 3), axis: .vertical, spacing: FlowSpacing(main: 1), children: [
            FlowChild(Label("Swiftual demo", frame: Rect(x: 0, y: 0, width: max(0, showcaseFrame.width), height: 1), style: backgroundStyle)),
            FlowChild(Label("Use mouse or keyboard: arrows, Enter, Escape. File > Quit exits.", frame: Rect(x: 0, y: 0, width: max(0, showcaseFrame.width), height: 1), style: backgroundStyle))
        ])
        let formControls = FlowContainer(frame: Rect(x: 0, y: 0, width: showcaseFrame.width, height: formHeight), axis: .horizontal, spacing: FlowSpacing(main: 2), children: [
            FlowChild(button),
            FlowChild(textInput),
            FlowChild(checkbox),
            FlowChild(toggleSwitch),
            FlowChild(select)
        ])
        let labelRow = FlowContainer(frame: Rect(x: 0, y: 0, width: showcaseFrame.width, height: labelHeight), axis: .horizontal, spacing: FlowSpacing(main: 2), children: demoLabels.map { FlowChild($0) })
        let buttonRow = FlowContainer(frame: Rect(x: 0, y: 0, width: showcaseFrame.width, height: demoButtonHeight), axis: .horizontal, spacing: FlowSpacing(main: 2), children: demoButtons.map { FlowChild($0) })
        let labelButtonPanel = FlowContainer(frame: Rect(x: 0, y: 0, width: showcaseFrame.width, height: 3), axis: .vertical, spacing: FlowSpacing(main: 1), children: [
            FlowChild(labelRow, preferences: LayoutPreferences(width: .fill, height: .auto)),
            FlowChild(buttonRow, preferences: LayoutPreferences(width: .fill, height: .auto))
        ])
        let vertical = Vertical(frame: Rect(x: 0, y: 0, width: 30, height: 5), spacing: 1, children: [])
        let horizontal = Horizontal(frame: Rect(x: 0, y: 0, width: 38, height: 3), spacing: 2, children: [])
        let containerPanel = FlowContainer(frame: Rect(x: 0, y: 0, width: showcaseFrame.width, height: 5), axis: .horizontal, spacing: FlowSpacing(main: 3), children: [
            FlowChild(vertical),
            FlowChild(horizontal),
            FlowChild(dataTable),
            FlowChild(scrollView),
            FlowChild(tree)
        ])
        let progressButton = Button("Animate", frame: Rect(x: 0, y: 0, width: 12, height: 1))
        let progressPanel = FlowContainer(frame: Rect(x: 0, y: 0, width: max(progressBar.frame.width, progressButton.frame.width), height: 3), axis: .vertical, spacing: FlowSpacing(main: 1), alignment: FlowAlignment(horizontal: .center, vertical: .top), children: [
            FlowChild(progressBar),
            FlowChild(progressButton)
        ])
        let workerButton = Button(workerButtonTitle, frame: Rect(x: 0, y: 0, width: 14, height: 1))
        let workerProgress = ProgressBar(frame: Rect(x: 0, y: 0, width: 30, height: 1), value: workerManager.state == .idle ? 0 : workerManager.progress, label: "Worker")
        let workerPanel = FlowContainer(frame: Rect(x: 0, y: 0, width: max(workerProgress.frame.width, workerButton.frame.width), height: 3), axis: .vertical, spacing: FlowSpacing(main: 1), children: [
            FlowChild(workerButton),
            FlowChild(workerProgress)
        ])
        let modalButton = Button("Show modal", frame: Rect(x: 0, y: 0, width: 14, height: 1))
        let commandButton = Button("Commands", frame: Rect(x: 0, y: 0, width: 14, height: 1))
        let actionsPanel = FlowContainer(frame: Rect(x: 0, y: 0, width: showcaseFrame.width, height: 3), axis: .horizontal, spacing: FlowSpacing(main: 3), children: [
            FlowChild(modalButton),
            FlowChild(progressPanel),
            FlowChild(commandButton),
            FlowChild(splitClampSwitch),
            FlowChild(workerPanel)
        ])
        let root = FlowContainer(frame: showcaseFrame, axis: .vertical, spacing: FlowSpacing(main: 1), overflow: .hidden, children: [
            FlowChild(introPanel, preferences: introPanelPreferences),
            FlowChild(formControls, preferences: formControlsPreferences),
            FlowChild(labelButtonPanel, preferences: labelButtonPanelPreferences),
            FlowChild(containerPanel, preferences: containerPanelPreferences),
            FlowChild(actionsPanel, preferences: actionsPanelPreferences)
        ])
        let rootFrames = root.laidOutChildren()

        let formFrame = rootFrames[safe: 1] ?? Rect(x: showcaseFrame.x, y: showcaseFrame.y + 4, width: showcaseFrame.width, height: formHeight)
        let labelButtonFrame = rootFrames[safe: 2] ?? Rect(x: showcaseFrame.x, y: formFrame.y + formFrame.height + 1, width: showcaseFrame.width, height: 3)
        let containerFrame = rootFrames[safe: 3] ?? Rect(x: showcaseFrame.x, y: labelButtonFrame.y + labelButtonFrame.height + 1, width: showcaseFrame.width, height: 5)
        let actionsFrame = rootFrames[safe: 4] ?? Rect(x: showcaseFrame.x, y: containerFrame.y + containerFrame.height + 1, width: showcaseFrame.width, height: 3)

        let formFrames = FlowContainer(frame: formFrame, axis: .horizontal, spacing: FlowSpacing(main: 2), children: [
            FlowChild(button),
            FlowChild(textInput),
            FlowChild(checkbox),
            FlowChild(toggleSwitch),
            FlowChild(select)
        ]).laidOutChildren()

        let labelButtonFrames = FlowContainer(frame: labelButtonFrame, axis: .vertical, spacing: FlowSpacing(main: 1), children: [
            FlowChild(labelRow, preferences: LayoutPreferences(width: .fill, height: .auto)),
            FlowChild(buttonRow, preferences: LayoutPreferences(width: .fill, height: .auto))
        ]).laidOutChildren()
        let labelFrames = FlowContainer(frame: labelButtonFrames[safe: 0] ?? labelButtonFrame, axis: .horizontal, spacing: FlowSpacing(main: 2), children: demoLabels.map { FlowChild($0) }).laidOutChildren()
        let demoButtonFrames = FlowContainer(frame: labelButtonFrames[safe: 1] ?? labelButtonFrame, axis: .horizontal, spacing: FlowSpacing(main: 2), children: demoButtons.map { FlowChild($0) }).laidOutChildren()

        let containerFrames = FlowContainer(frame: containerFrame, axis: .horizontal, spacing: FlowSpacing(main: 3), overflow: Overflow(x: .hidden, y: .hidden), children: [
            FlowChild(vertical),
            FlowChild(horizontal),
            FlowChild(dataTable),
            FlowChild(scrollView),
            FlowChild(tree)
        ]).laidOutChildren()

        let actionsFrames = FlowContainer(frame: actionsFrame, axis: .horizontal, spacing: FlowSpacing(main: 3), children: [
            FlowChild(modalButton),
            FlowChild(progressPanel),
            FlowChild(commandButton),
            FlowChild(splitClampSwitch),
            FlowChild(workerPanel)
        ]).laidOutChildren()
        let progressFrames = FlowContainer(frame: actionsFrames[safe: 1] ?? actionsFrame, axis: .vertical, spacing: FlowSpacing(main: 1), alignment: FlowAlignment(horizontal: .center, vertical: .top), children: [
            FlowChild(progressBar),
            FlowChild(progressButton)
        ]).laidOutChildren()
        let workerFrames = FlowContainer(frame: actionsFrames[safe: 4] ?? actionsFrame, axis: .vertical, spacing: FlowSpacing(main: 1), children: [
            FlowChild(workerButton),
            FlowChild(workerProgress)
        ]).laidOutChildren()

        return ShowcaseLayout(
            buttonFrame: formFrames[safe: 0] ?? Rect(x: formFrame.x, y: formFrame.y, width: button.frame.width, height: button.frame.height),
            textInputFrame: formFrames[safe: 1] ?? Rect(x: formFrame.x, y: formFrame.y, width: textInput.frame.width, height: textInput.frame.height),
            checkboxFrame: formFrames[safe: 2] ?? Rect(x: formFrame.x, y: formFrame.y, width: checkbox.frame.width, height: checkbox.frame.height),
            switchFrame: formFrames[safe: 3] ?? Rect(x: formFrame.x, y: formFrame.y, width: toggleSwitch.frame.width, height: toggleSwitch.frame.height),
            selectFrame: formFrames[safe: 4] ?? Rect(x: formFrame.x, y: formFrame.y, width: select.frame.width, height: select.frame.height),
            labelFrames: labelFrames,
            demoButtonFrames: demoButtonFrames,
            verticalFrame: containerFrames[safe: 0] ?? containerFrame,
            horizontalFrame: containerFrames[safe: 1] ?? containerFrame,
            dataTableFrame: containerFrames[safe: 2] ?? containerFrame,
            scrollViewFrame: containerFrames[safe: 3] ?? containerFrame,
            treeFrame: containerFrames[safe: 4] ?? containerFrame,
            modalButtonFrame: actionsFrames[safe: 0] ?? actionsFrame,
            progressBarFrame: progressFrames[safe: 0] ?? actionsFrame,
            progressButtonFrame: progressFrames[safe: 1] ?? actionsFrame,
            commandButtonFrame: actionsFrames[safe: 2] ?? actionsFrame,
            splitClampSwitchFrame: actionsFrames[safe: 3] ?? actionsFrame,
            workerButtonFrame: workerFrames[safe: 0] ?? actionsFrame,
            workerProgressFrame: workerFrames[safe: 1] ?? actionsFrame
        )
    }

    private func rect(from preferences: LayoutPreferences, defaultFrame: Rect, parentFrame: Rect) -> Rect {
        let width = resolved(preferences.width, intrinsic: defaultFrame.width, available: parentFrame.width)
        let height = resolved(preferences.height, intrinsic: defaultFrame.height, available: parentFrame.height)
        return Rect(
            x: defaultFrame.x,
            y: defaultFrame.y,
            width: clamp(width, min: preferences.minWidth, max: preferences.maxWidth),
            height: clamp(height, min: preferences.minHeight, max: preferences.maxHeight)
        )
    }

    private func resolved(_ length: LayoutLength, intrinsic: Int, available: Int) -> Int {
        switch length {
        case .cells(let value):
            return value
        case .fraction, .fill:
            return available
        case .percent(let value):
            return Int((Double(available) * value).rounded(.down))
        case .auto:
            return intrinsic
        }
    }

    private func clamp(_ value: Int, min minimum: Int, max maximum: Int?) -> Int {
        Swift.min(Swift.max(0, Swift.max(minimum, value)), maximum ?? Int.max)
    }

    public static let defaultShowcasePreferences = LayoutPreferences(width: .fill, height: .fill)
    public static let defaultIntroPanelPreferences = LayoutPreferences(width: .fill, height: .auto)
    public static let defaultFormControlsPreferences = LayoutPreferences(width: .fill, height: .auto)
    public static let defaultLabelButtonPanelPreferences = LayoutPreferences(width: .fill, height: .auto)
    public static let defaultContainerPanelPreferences = LayoutPreferences(width: .fill, height: .auto)
    public static let defaultActionsPanelPreferences = LayoutPreferences(width: .fill, height: .auto)

    public static func defaultDemoLabels() -> [Label] {
        [
            Label(
                "Left label",
                frame: Rect(x: 2, y: 9, width: 18, height: 1),
                style: TerminalStyle(foreground: .brightWhite, background: .brightBlack),
                alignment: .left
            ),
            Label(
                "Centered",
                frame: Rect(x: 22, y: 9, width: 18, height: 1),
                style: TerminalStyle(foreground: .black, background: .cyan, bold: true),
                alignment: .center
            ),
            Label(
                "Right",
                frame: Rect(x: 42, y: 9, width: 18, height: 1),
                style: TerminalStyle(foreground: .yellow, background: .blue),
                alignment: .right
            )
        ]
    }

    public static func defaultDemoButtons() -> [Button] {
        [
            Button("Normal", frame: Rect(x: 2, y: 11, width: 14, height: 1)),
            Button("Focused", frame: Rect(x: 18, y: 11, width: 14, height: 1), isFocused: true),
            Button("Disabled", frame: Rect(x: 34, y: 11, width: 14, height: 1), isEnabled: false)
        ]
    }
}

public enum MainViewFocus: Equatable, Sendable {
    case menuBar
    case button
    case textInput
    case checkbox
    case `switch`
    case select
    case scrollView
    case modalButton
    case progressButton
    case dataTable
    case tree
    case commandPaletteButton
    case splitClampSwitch
    case workerButton

    var next: MainViewFocus {
        switch self {
        case .menuBar:
            return .button
        case .button:
            return .textInput
        case .textInput:
            return .checkbox
        case .checkbox:
            return .switch
        case .switch:
            return .select
        case .select:
            return .scrollView
        case .scrollView:
            return .modalButton
        case .modalButton:
            return .progressButton
        case .progressButton:
            return .dataTable
        case .dataTable:
            return .tree
        case .tree:
            return .commandPaletteButton
        case .commandPaletteButton:
            return .splitClampSwitch
        case .splitClampSwitch:
            return .workerButton
        case .workerButton:
            return .menuBar
        }
    }
}

private struct ShowcaseLayout {
    var buttonFrame: Rect
    var textInputFrame: Rect
    var checkboxFrame: Rect
    var switchFrame: Rect
    var selectFrame: Rect
    var labelFrames: [Rect]
    var demoButtonFrames: [Rect]
    var verticalFrame: Rect
    var horizontalFrame: Rect
    var dataTableFrame: Rect
    var scrollViewFrame: Rect
    var treeFrame: Rect
    var modalButtonFrame: Rect
    var progressBarFrame: Rect
    var progressButtonFrame: Rect
    var commandButtonFrame: Rect
    var splitClampSwitchFrame: Rect
    var workerButtonFrame: Rect
    var workerProgressFrame: Rect
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
