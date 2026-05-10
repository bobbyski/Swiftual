import XCTest
@testable import Swiftual

final class SwiftualFrameworkTests: XCTestCase {
    func testMenuBarCoreMovedWithoutDemoContainer() {
        var menuBar = MenuBar(menus: [
            Menu("File", items: [
                MenuItem("Quit") {}
            ])
        ])

        XCTAssertEqual(menuBar.handle(.key(.down)), .none)
        XCTAssertTrue(menuBar.isOpen)
        XCTAssertEqual(menuBar.handle(.key(.enter)), .quit)
    }

    func testCoreControlStillRenders() {
        var canvas = Canvas(size: TerminalSize(columns: 12, rows: 3))
        Button("Run", frame: Rect(x: 1, y: 1, width: 8, height: 1)).render(in: &canvas)

        XCTAssertEqual(canvas[3, 1].character, "R")
        XCTAssertEqual(canvas[1, 1].style.background, .brightWhite)
    }
}
