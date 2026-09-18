// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "BooloopCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "BooloopCore", targets: ["BooloopCore"]),
    ],
    targets: [
        .target(name: "BooloopCore"),
        .testTarget(
            name: "BooloopCoreTests",
            dependencies: ["BooloopCore"],
            exclude: ["Fixtures"]
        ),
    ]
)
