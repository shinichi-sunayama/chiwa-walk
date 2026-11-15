// swift-tools-version:5.9
// Walk-log logic shared by the iPhone and Apple Watch apps (no UI, no storage).
// Tested on Linux in GitHub Actions (ci.yml): `swift test` in this folder.
import PackageDescription

let package = Package(
    name: "WalkCore",
    platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v14)],
    products: [
        .library(name: "WalkCore", targets: ["WalkCore"]),
    ],
    targets: [
        .target(name: "WalkCore"),
        .testTarget(name: "WalkCoreTests", dependencies: ["WalkCore"]),
    ]
)
