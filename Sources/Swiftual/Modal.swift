import Foundation

public struct ModalButton: Equatable, Sendable {
    public var title: String
    public var isEnabled: Bool

    public init(_ title: String, isEnabled: Bool = true) {
        self.title = title
        self.isEnabled = isEnabled
    }
}

public struct Modal: CanvasRenderable, Equatable, Sendable {
    public var frame: Rect
    public var title: String
    public var message: String
    public var buttons: [ModalButton]
    public var selectedButtonIndex: Int
    public var isPresented: Bool
    public var drawsOverlayBackground: Bool
    public var overlayStyle: TerminalStyle
    public var panelStyle: TerminalStyle
    public var titleStyle: TerminalStyle
    public var buttonStyle: TerminalStyle
    public var focusedButtonStyle: TerminalStyle
    public var disabledButtonStyle: TerminalStyle

    public init(
        frame: Rect,
        title: String,
        message: String,
        buttons: [ModalButton] = [ModalButton("OK")],
        selectedButtonIndex: Int = 0,
        isPresented: Bool = false,
        drawsOverlayBackground: Bool = false,
        overlayStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .brightBlack),
        panelStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        titleStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true),
        buttonStyle: TerminalStyle = TerminalStyle(foreground: .black, background: .brightWhite),
        focusedButtonStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true),
        disabledButtonStyle: TerminalStyle = TerminalStyle(foreground: .white, background: .brightBlack)
    ) {
        self.frame = frame
        self.title = title
        self.message = message
        self.buttons = buttons
        let fallbackIndex = buttons.indices.first ?? 0
        self.selectedButtonIndex = buttons.indices.contains(selectedButtonIndex) ? selectedButtonIndex : fallbackIndex
        self.isPresented = isPresented
        self.drawsOverlayBackground = drawsOverlayBackground
        self.overlayStyle = overlayStyle
        self.panelStyle = panelStyle
        self.titleStyle = titleStyle
        self.buttonStyle = buttonStyle
        self.focusedButtonStyle = focusedButtonStyle
        self.disabledButtonStyle = disabledButtonStyle
    }

    public mutating func present() {
        isPresented = true
        selectedButtonIndex = firstEnabledButtonIndex()
    }

    public mutating func dismiss() {
        isPresented = false
    }

    public mutating func handle(_ event: InputEvent) -> ModalCommand {
        guard isPresented else { return .none }

        switch event {
        case .key(.escape):
            dismiss()
            return .dismissed
        case .key(.left):
            moveSelection(delta: -1)
            return .highlighted(selectedButtonIndex)
        case .key(.right), .key(.tab):
            moveSelection(delta: 1)
            return .highlighted(selectedButtonIndex)
        case .key(.enter), .key(.character(" ")):
            guard buttons.indices.contains(selectedButtonIndex), buttons[selectedButtonIndex].isEnabled else {
                return .none
            }
            let title = buttons[selectedButtonIndex].title
            dismiss()
            return .selected(selectedButtonIndex, title)
        case .mouse(let mouse):
            guard mouse.pressed, mouse.button == .left else { return .none }
            if let index = buttonIndex(at: mouse.location), buttons[index].isEnabled {
                selectedButtonIndex = index
                let title = buttons[index].title
                dismiss()
                return .selected(index, title)
            }
            if !frame.contains(mouse.location) {
                dismiss()
                return .dismissed
            }
            return .none
        default:
            return .none
        }
    }

    public func render(in canvas: inout Canvas) {
        guard isPresented else { return }
        if drawsOverlayBackground {
            canvas.fill(rect: Rect(x: 0, y: 0, width: canvas.size.columns, height: canvas.size.rows), style: overlayStyle)
        }
        canvas.fill(rect: frame, style: panelStyle)

        canvas.fill(rect: Rect(x: frame.x, y: frame.y, width: frame.width, height: 1), style: titleStyle)
        canvas.drawText(centered(title, width: frame.width), at: Point(x: frame.x, y: frame.y), style: titleStyle)

        let messageFrame = Rect(x: frame.x + 2, y: frame.y + 2, width: max(0, frame.width - 4), height: 1)
        canvas.drawText(String(message.prefix(messageFrame.width)), at: Point(x: messageFrame.x, y: messageFrame.y), style: panelStyle)

        renderButtons(in: &canvas)
    }

    private func renderButtons(in canvas: inout Canvas) {
        guard !buttons.isEmpty else { return }
        let buttonY = frame.y + frame.height - 2
        var x = frame.x + 2
        for index in buttons.indices {
            let button = buttons[index]
            let width = button.title.count + 4
            let style: TerminalStyle
            if !button.isEnabled {
                style = disabledButtonStyle
            } else if index == selectedButtonIndex {
                style = focusedButtonStyle
            } else {
                style = buttonStyle
            }
            let rect = Rect(x: x, y: buttonY, width: width, height: 1)
            canvas.fill(rect: rect, style: style)
            canvas.drawText(" \(button.title) ", at: Point(x: x + 1, y: buttonY), style: style)
            x += width + 1
        }
    }

    private func centered(_ text: String, width: Int) -> String {
        let visible = String(text.prefix(width))
        let left = max(0, (width - visible.count) / 2)
        return String(repeating: " ", count: left) + visible
    }

    private mutating func moveSelection(delta: Int) {
        guard !buttons.isEmpty else { return }
        var next = selectedButtonIndex
        for _ in buttons.indices {
            next = (next + delta + buttons.count) % buttons.count
            if buttons[next].isEnabled {
                selectedButtonIndex = next
                return
            }
        }
    }

    private func firstEnabledButtonIndex() -> Int {
        buttons.firstIndex(where: \.isEnabled) ?? 0
    }

    private func buttonIndex(at point: Point) -> Int? {
        let buttonY = frame.y + frame.height - 2
        guard point.y == buttonY else { return nil }
        var x = frame.x + 2
        for index in buttons.indices {
            let width = buttons[index].title.count + 4
            if point.x >= x, point.x < x + width {
                return index
            }
            x += width + 1
        }
        return nil
    }
}

public enum ModalCommand: Equatable, Sendable {
    case none
    case dismissed
    case highlighted(Int)
    case selected(Int, String)
}
