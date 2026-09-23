// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DeepSeekStatus",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "DeepSeekStatus",
            targets: ["DeepSeekStatus"]
        )
    ],
    targets: [
        .executableTarget(
            name: "DeepSeekStatus",
            path: "Sources"
        )
    ]
)
