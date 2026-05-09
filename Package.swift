// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "Swiftual",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "Swiftual",
            targets: ["Swiftual"]
        ),
        .executable(
            name: "swiftual-demo",
            targets: ["SwiftualDemo"]
        )
    ],
    dependencies: [
        .package(path: "../RichSwift")
    ],
    targets: [
        .target(
            name: "Swiftual",
            dependencies: ["RichSwift"]
        ),
        .executableTarget(
            name: "SwiftualDemo",
            dependencies: ["Swiftual"]
        ),
        .testTarget(
            name: "SwiftualTests",
            dependencies: ["Swiftual"]
        )
    ],
    swiftLanguageModes: [.v6]
)
