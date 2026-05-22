// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PipeBirdCore",
    products: [
        .library(name: "PipeBirdCore", targets: ["PipeBirdCore"])
    ],
    targets: [
        .target(name: "PipeBirdCore"),
        .testTarget(
            name: "PipeBirdCoreTests",
            dependencies: ["PipeBirdCore"]
        )
    ]
)
