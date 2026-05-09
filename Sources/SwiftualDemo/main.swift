import Swiftual
import Darwin
import Foundation

let selection: TerminalBackendSelection
if CommandLine.arguments.contains("--vt100") {
    selection = .manual(.vt100)
} else if CommandLine.arguments.contains("--ansi") {
    selection = .manual(.ansi)
} else {
    selection = .automatic
}

let app = MenuDemoApplication(configuration: MenuDemoConfiguration(backendSelection: selection))

do {
    try app.run()
} catch {
    FileHandle.standardError.write(Data("swiftual-demo failed: \(error)\n".utf8))
    exit(1)
}
