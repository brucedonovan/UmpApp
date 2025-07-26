// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UmpApp",
    platforms: [
        .iOS(.v15),
        .watchOS(.v8),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "UmpAppCore",
            targets: ["UmpAppCore"]),
        .executable(
            name: "UmpApp_iOS",
            targets: ["UmpApp_iOS"]),
    ],
    targets: [
        .target(
            name: "UmpAppCore",
            dependencies: [],
            path: "Sources/UmpAppCore"
        ),
        .executableTarget(
            name: "UmpApp_iOS",
            dependencies: ["UmpAppCore"],
            path: "iOS"
        ),
        .testTarget(
            name: "UmpAppCoreTests",
            dependencies: ["UmpAppCore"],
            path: "Tests/UmpAppCoreTests"
        ),
    ]
)
