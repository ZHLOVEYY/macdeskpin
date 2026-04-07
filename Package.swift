// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DeskPin",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "DeskPin",
            path: "Sources/DeskPin"
        )
    ]
)
