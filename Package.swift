// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Draughts",
    products: [
        .library(
            name: "Draughts",
            targets: ["Draughts"]
        ),
    ],
    dependencies: [
        .package(
            name: "Parser",
            url: "https://github.com/timvermeulen/swift-parser",
            from: .init(0, 0, 15)
        ),
    ],
    targets: [
        .target(
            name: "Draughts",
            dependencies: ["Parser"]
        ),
        .testTarget(
            name: "DraughtsTests",
            dependencies: ["Draughts"]
        ),
    ]
)
