import Foundation

public struct MenuDemoConfiguration: Sendable {
    public var backendSelection: TerminalBackendSelection

    public init(backendSelection: TerminalBackendSelection = .automatic) {
        self.backendSelection = backendSelection
    }
}

public final class MenuDemoApplication: @unchecked Sendable {
    private let device: TerminalDevice
    private let backend: TerminalBackend
    private var view: MainViewContainer
    private var shouldQuit = false

    public init(
        configuration: MenuDemoConfiguration = MenuDemoConfiguration(),
        device: TerminalDevice = FileDescriptorTerminalDevice()
    ) {
        self.device = device
        self.backend = TerminalDetector.detect(selection: configuration.backendSelection)
        self.view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit", shortcut: "Q") {}
                    ])
                ]
            )
        )
    }

    public func run() throws {
        try device.enableRawMode()
        try backend.enterApplicationMode(device: device)
        defer {
            try? backend.exitApplicationMode(device: device)
            device.restoreMode()
        }

        try render()
        while !shouldQuit {
            let bytes = try device.readInput(maxBytes: 64)
            for event in backend.decodeInput(bytes) {
                let command = view.handle(event)
                if command == .quit {
                    shouldQuit = true
                }
            }
            view.updateProgressAnimation()
            view.updateWorkerEvents()
            try render()
        }
    }

    private func render() throws {
        let canvas = view.render(size: device.size())
        try backend.render(canvas, device: device)
    }
}
