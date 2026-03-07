// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DangerTools",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "DangerDeps",
            type: .dynamic,
            targets: ["DangerDeps"]
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
    ]
)
