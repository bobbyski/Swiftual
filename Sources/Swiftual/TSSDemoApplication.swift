import Foundation

public final class TSSDemoApplication: @unchecked Sendable {
    private let device: TerminalDevice
    private let backend: TerminalBackend
    private var view: TSSDemoViewContainer
    private var shouldQuit = false

    public init(
        configuration: MenuDemoConfiguration = MenuDemoConfiguration(),
        device: TerminalDevice = FileDescriptorTerminalDevice()
    ) {
        self.device = device
        self.backend = TerminalDetector.detect(selection: configuration.backendSelection)
        self.view = TSSDemoViewContainer(baseDemo: TSSDemoViewContainer.frozenBaseDemo())
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
            let size = device.size()
            let bytes = try device.readInput(maxBytes: 64)
            for event in backend.decodeInput(bytes) {
                let command = view.handle(event, terminalSize: size)
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
