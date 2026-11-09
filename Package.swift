// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LimitsWidget",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "LimitsWidget", targets: ["LimitsWidget"]),
        .library(name: "LimitsCore", targets: ["LimitsCore"]),
    ],
    targets: [
        .target(name: "LimitsCore"),
        .executableTarget(
            name: "LimitsWidget",
            dependencies: ["LimitsCore"]
        ),
        .testTarget(
            name: "LimitsCoreTests",
            dependencies: ["LimitsCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
