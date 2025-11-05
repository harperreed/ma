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
        .package(url: "https://github.com/harperreed/MusicAssistantKit.git", from: "0.3.0"),
        .package(url: "https://github.com/harperreed/ResonateKit.git", from: "0.3.4")
    ],
    targets: [
        .executableTarget(
            name: "MusicAssistantPlayer",
            dependencies: [
                "MusicAssistantKit",
                "ResonateKit"
            ],
            path: "Sources/MusicAssistantPlayer"
        ),
        .testTarget(
            name: "MusicAssistantPlayerTests",
            dependencies: ["MusicAssistantPlayer"],
            path: "Tests/MusicAssistantPlayerTests"
        )
    ]
)
