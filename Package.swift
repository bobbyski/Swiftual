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
        .testTarget(
            name: "SwiftualTests",
            dependencies: ["Swiftual"]
        )
    ],
    swiftLanguageModes: [.v6]
)
