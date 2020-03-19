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
    targets: [
        .target(
            name: "Draughts",
            dependencies: []
        ),
        .testTarget(
            name: "DraughtsTests",
            dependencies: ["Draughts"]
        ),
    ]
)
