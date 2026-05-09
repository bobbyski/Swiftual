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
    public var backgroundStyle: TerminalStyle

    public init(
        menuBar: MenuBar,
        backgroundStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .brightBlack)
    ) {
        self.menuBar = menuBar
        self.backgroundStyle = backgroundStyle
    }

    public mutating func handle(_ event: InputEvent) -> MenuCommand {
        menuBar.handle(event)
    }

    public func render(size: TerminalSize) -> Canvas {
        var canvas = Canvas(size: size, fill: Cell(" ", style: backgroundStyle))
        canvas.fill(rect: Rect(x: 0, y: 1, width: size.columns, height: max(0, size.rows - 1)), style: backgroundStyle)
        canvas.drawText("Swiftual demo", at: Point(x: 2, y: 2), style: backgroundStyle)
        canvas.drawText("Use mouse or keyboard: arrows, Enter, Escape. File > Quit exits.", at: Point(x: 2, y: 4), style: backgroundStyle)
        let menuBar = menuBar
        menuBar.render(in: &canvas)
        return canvas
    }
}
