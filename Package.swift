// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MouseEyes",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MouseEyes",
            targets: ["MouseEyes"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MouseEyes",
            path: "Sources"
        )
    ]
)
