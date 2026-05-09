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

    public init(menus: [Menu]) {
        self.menus = menus
        self.selectedMenuIndex = 0
        self.openedMenuIndex = nil
        self.selectedItemIndex = 0
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
        let barStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true)
        let selectedBarStyle = TerminalStyle(foreground: .blue, background: .brightWhite, bold: true)
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
        let menuStyle = TerminalStyle(foreground: .black, background: .brightBlack)
        let selectedStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true)
        let disabledStyle = TerminalStyle(foreground: .white, background: .brightBlack)

        canvas.fill(rect: Rect(x: originX, y: 1, width: width, height: height), style: menuStyle)
        for itemIndex in menu.items.indices {
            let item = menu.items[itemIndex]
            let title = itemTitle(item, width: width)
            let style: TerminalStyle
            if itemIndex == selectedItemIndex {
                style = selectedStyle
            } else if item.isEnabled {
                style = menuStyle
            } else {
                style = disabledStyle
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
    public var demoButtons: [Button]
    public var demoLabels: [Label]
    public var backgroundStyle: TerminalStyle
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
        demoButtons: [Button] = MainViewContainer.defaultDemoButtons(),
        demoLabels: [Label] = MainViewContainer.defaultDemoLabels(),
        backgroundStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .brightBlack)
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
        self.demoButtons = demoButtons
        self.demoLabels = demoLabels
        self.backgroundStyle = backgroundStyle
        self.focusedControl = .menuBar
    }

    public mutating func handle(_ event: InputEvent) -> MenuCommand {
        if modal.isPresented {
            logModalCommand(modal.handle(event))
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

        let modalButton = Button("Show modal", frame: Rect(x: 36, y: 18, width: 14, height: 1))
        if case .mouse(let mouse) = event, mouse.pressed, mouse.button == .left, modalButton.frame.contains(mouse.location) {
            focusedControl = .modalButton
            modal.present()
            richLog.append("Modal opened.", style: TerminalStyle(foreground: .cyan, background: .black))
            return .none
        }

        let progressButton = Button("Animate", frame: Rect(x: 56, y: 19, width: 12, height: 1))
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

    public func render(size: TerminalSize) -> Canvas {
        var canvas = Canvas(size: size, fill: Cell(" ", style: backgroundStyle))
        canvas.fill(rect: Rect(x: 0, y: 1, width: size.columns, height: max(0, size.rows - 1)), style: backgroundStyle)
        Label("Swiftual demo", frame: Rect(x: 2, y: 2, width: max(0, size.columns - 4), height: 1), style: backgroundStyle).render(in: &canvas)
        Label(
            "Use mouse or keyboard: arrows, Enter, Escape. File > Quit exits.",
            frame: Rect(x: 2, y: 4, width: max(0, size.columns - 4), height: 1),
            style: backgroundStyle
        ).render(in: &canvas)

        for label in demoLabels {
            label.render(in: &canvas)
        }

        for button in demoButtons {
            button.render(in: &canvas)
        }

        let vertical = Vertical(
            frame: Rect(x: 2, y: 14, width: 30, height: 5),
            spacing: 1,
            fillStyle: TerminalStyle(foreground: .brightWhite, background: .black),
            children: [
                AnyCanvasRenderable(Label("Vertical stack", frame: Rect(x: 0, y: 0, width: 30, height: 1), style: TerminalStyle(foreground: .brightWhite, background: .black), alignment: .center)),
                AnyCanvasRenderable(Label("Child label", frame: Rect(x: 0, y: 0, width: 30, height: 1), style: TerminalStyle(foreground: .cyan, background: .black))),
                AnyCanvasRenderable(Button("Child button", frame: Rect(x: 0, y: 0, width: 16, height: 1)))
            ]
        )
        vertical.render(in: &canvas)

        let horizontal = Horizontal(
            frame: Rect(x: 36, y: 14, width: 36, height: 3),
            spacing: 2,
            fillStyle: TerminalStyle(foreground: .brightWhite, background: .black),
            children: [
                AnyCanvasRenderable(Label("Horizontal", frame: Rect(x: 0, y: 0, width: 12, height: 1), style: TerminalStyle(foreground: .brightWhite, background: .black))),
                AnyCanvasRenderable(Button("One", frame: Rect(x: 0, y: 0, width: 8, height: 1))),
                AnyCanvasRenderable(Button("Two", frame: Rect(x: 0, y: 0, width: 8, height: 1), isFocused: true))
            ]
        )
        horizontal.render(in: &canvas)

        Button("Show modal", frame: Rect(x: 36, y: 18, width: 14, height: 1), isFocused: focusedControl == .modalButton).render(in: &canvas)
        progressBar.render(in: &canvas)
        Button("Animate", frame: Rect(x: 56, y: 19, width: 12, height: 1), isFocused: focusedControl == .progressButton).render(in: &canvas)

        var button = button
        button.isFocused = focusedControl == .button
        button.render(in: &canvas)
        var textInput = textInput
        textInput.isFocused = focusedControl == .textInput
        textInput.render(in: &canvas)
        var checkbox = checkbox
        checkbox.isFocused = focusedControl == .checkbox
        checkbox.render(in: &canvas)
        var toggleSwitch = toggleSwitch
        toggleSwitch.isFocused = focusedControl == .switch
        toggleSwitch.render(in: &canvas)
        var select = select
        select.isFocused = focusedControl == .select
        select.render(in: &canvas)
        var scrollView = scrollView
        scrollView.isFocused = focusedControl == .scrollView
        scrollView.render(in: &canvas)
        richLog.render(in: &canvas)
        modal.render(in: &canvas)
        let menuBar = menuBar
        menuBar.render(in: &canvas)
        return canvas
    }

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
            return .menuBar
        }
    }
}
