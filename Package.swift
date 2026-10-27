// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "GrantKit",
    platforms: [
        .macOS("26.0"),
        .iOS("26.0"),
    ],
    products: [
        .library(name: "GrantKit", targets: ["GrantKit"]),
        .executable(name: "GrantKitDemo", targets: ["GrantKitDemo"]),
    ],
    targets: [
        .target(name: "GrantKit"),
        .executableTarget(
            name: "GrantKitDemo",
            dependencies: ["GrantKit"],
            path: "Demo"
        ),
        .testTarget(name: "GrantKitTests", dependencies: ["GrantKit"]),
    ]
)
