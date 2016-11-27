import PackageDescription

let package = Package(
    name: "Draughts",
    dependencies: [
        .Package(url: "https://github.com/timvermeulen/Parser", Version(0, 0, 2))
    ]
)
