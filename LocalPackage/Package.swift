// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LocalPackage",
    platforms: [.iOS(.v17), .macOS(.v15)],
    products: [
        .library(
            name: "HometeDomain",
            targets: ["HometeDomain"]
        ),
        .library(
            name: "HometeUI",
            targets: ["HometeUI"]
        ),
        .library(
            name: "HometeResources",
            targets: ["HometeResources"]
        ),
    ],
    dependencies: [
        .package(path: "../ProjectTools"),
        .package(url: "https://github.com/SwiftGen/SwiftGenPlugin", from: "6.6.2")
    ],
    targets: [
        .target(
            name: "HometeDomain",
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
        .target(
            name: "HometeUI",
            dependencies: [
                "HometeDomain",
                "HometeResources",
            ],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
        .target(
            name: "HometeResources",
            plugins: [
                .plugin(name: "SwiftGenPlugin", package: "SwiftGenPlugin")
            ]
        ),
        .testTarget(
            name: "HometeDomainTests",
            dependencies: ["HometeDomain"],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
    ]
)
