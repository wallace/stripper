// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Stripper",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Stripper", targets: ["Stripper"]),
        .library(name: "StripperCore", targets: ["StripperCore"]),
    ],
    targets: [
        .target(name: "StripperCore"),
        .executableTarget(name: "Stripper", dependencies: ["StripperCore"]),
        .testTarget(name: "StripperCoreTests", dependencies: ["StripperCore"]),
    ]
)
