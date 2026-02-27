// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TeamsAlert",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "TeamsAlert",
            path: "Sources/TeamsAlert",
            exclude: ["Resources/Info.plist"]
        )
    ]
)
