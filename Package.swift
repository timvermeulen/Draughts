import PackageDescription

let package = Package(
    name: "Draughts",
    dependencies: [
        .Package(url: "https://github.com/timvermeulen/SafeXCTestCase", Version(1, 0, 0))
    ],
    exclude: ["Tests"]
)
