// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProjectTools",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "DangerDeps",
            type: .dynamic,
            targets: ["DangerDeps"]
        ),
        .plugin(
            name: "SwiftLintPlugin",
            targets: ["SwiftLintPlugin"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/danger/swift.git", exact: "3.22.0"),
        .package(url: "https://github.com/f-meloni/danger-swift-coverage", from: "1.2.1"),
    ],
    targets: [
        .target(
            name: "DangerDeps",
            dependencies: [
                .product(name: "Danger", package: "swift"),
                .product(name: "DangerSwiftCoverage", package: "danger-swift-coverage"),
            ]
        ),
        .plugin(
            name: "SwiftLintPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "SwiftLintBinary"),
            ]
        ),
        .binaryTarget(
            name: "SwiftLintBinary",
            url: "https://github.com/realm/SwiftLint/releases/download/0.59.1/SwiftLintBinary.artifactbundle.zip",
            checksum: "b9f915a58a818afcc66846740d272d5e73f37baf874e7809ff6f246ea98ad8a2"
        ),
    ]
)
