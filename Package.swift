import PackageDescription

let package = Package(
    name: "Draughts",
    dependencies: [
        .Package(url: "https://github.com/timvermeulen/Parser.git", majorVersion: 0)
    ]
)
