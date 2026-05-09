import XCTest
@testable import Swiftual

final class SwiftualTests: XCTestCase {
    func testTerminalDetectorCanSelectANSIManually() {
        let backend = TerminalDetector.detect(selection: .manual(.ansi))
        XCTAssertEqual(backend.kind, .ansi)
    }

    func testTerminalDetectorCanSelectVT100Manually() {
        let backend = TerminalDetector.detect(selection: .manual(.vt100))
        XCTAssertEqual(backend.kind, .vt100)
    }

    func testMenuOpensAndQuitActivatesWithKeyboard() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertEqual(view.handle(.key(.down)), .none)
        XCTAssertEqual(view.handle(.key(.enter)), .quit)
    }

    func testMenuOpensAndQuitActivatesWithMouse() {
        var view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 1, y: 0), pressed: true))), .none)
        XCTAssertEqual(view.handle(.mouse(MouseEvent(button: .left, location: Point(x: 1, y: 1), pressed: true))), .quit)
    }

    func testRenderContainsBlueMenuBarAndGreyBody() {
        let view = MainViewContainer(
            menuBar: MenuBar(
                menus: [
                    Menu("File", items: [
                        MenuItem("Quit") {}
                    ])
                ]
            )
        )

        let canvas = view.render(size: TerminalSize(columns: 20, rows: 6))
        XCTAssertEqual(canvas[0, 0].style.background, .blue)
        XCTAssertEqual(canvas[8, 0].style.background, .blue)
        XCTAssertEqual(canvas[0, 1].style.background, .brightBlack)
    }

    func testFocusedMenuMatchesMenuBarUntilOpened() {
        var menuBar = MenuBar(
            menus: [
                Menu("File", items: [
                    MenuItem("Quit") {}
                ])
            ]
        )
        var canvas = Canvas(size: TerminalSize(columns: 20, rows: 4))

        menuBar.render(in: &canvas)
        XCTAssertEqual(canvas[1, 0].style.foreground, .brightWhite)
        XCTAssertEqual(canvas[1, 0].style.background, .blue)

        _ = menuBar.handle(.key(.down))
        canvas = Canvas(size: TerminalSize(columns: 20, rows: 4))
        menuBar.render(in: &canvas)
        XCTAssertEqual(canvas[1, 0].style.foreground, .blue)
        XCTAssertEqual(canvas[1, 0].style.background, .brightWhite)
    }

    func testANSIBackendRendersThroughTerminalDeviceProtocol() throws {
        let device = VirtualTerminalDevice(size: TerminalSize(columns: 6, rows: 2))
        let backend = ANSITerminalBackend()
        var canvas = Canvas(size: device.size())
        canvas.drawText("Hi", at: Point(x: 0, y: 0), style: TerminalStyle(foreground: .white, background: .blue))

        try backend.render(canvas, device: device)

        XCTAssertTrue(device.output.contains("\u{001B}[H"))
        XCTAssertTrue(device.output.contains("Hi"))
        XCTAssertTrue(device.output.contains("\u{001B}[37;44m"))
    }

    func testANSIBackendDoesNotScrollLastRenderedRow() throws {
        let device = VirtualTerminalDevice(size: TerminalSize(columns: 4, rows: 2))
        let backend = ANSITerminalBackend()
        var canvas = Canvas(size: device.size())
        canvas.drawText("Menu", at: Point(x: 0, y: 0), style: TerminalStyle(foreground: .white, background: .blue))
        canvas.drawText("Body", at: Point(x: 0, y: 1), style: TerminalStyle(foreground: .white, background: .brightBlack))

        try backend.render(canvas, device: device)

        XCTAssertFalse(device.output.hasSuffix("\r\n"))
    }
}

private final class VirtualTerminalDevice: TerminalDevice, @unchecked Sendable {
    var output = ""
    private let terminalSize: TerminalSize

    init(size: TerminalSize) {
        self.terminalSize = size
    }

    func readInput(maxBytes: Int) throws -> [UInt8] {
        []
    }

    func writeOutput(_ output: String) throws {
        self.output += output
    }

    func size() -> TerminalSize {
        terminalSize
    }

    func enableRawMode() throws {}

    func restoreMode() {}
}
