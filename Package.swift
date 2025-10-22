// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MusicAssistantPlayer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "MusicAssistantPlayer",
            targets: ["MusicAssistantPlayer"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/harperreed/MusicAssistantKit.git", from: "0.2.1")
    ],
    targets: [
        .executableTarget(
            name: "MusicAssistantPlayer",
            dependencies: ["MusicAssistantKit"],
            path: "Sources/MusicAssistantPlayer"
        ),
        .testTarget(
            name: "MusicAssistantPlayerTests",
            dependencies: ["MusicAssistantPlayer"],
            path: "Tests/MusicAssistantPlayerTests"
        )
    ]
)
