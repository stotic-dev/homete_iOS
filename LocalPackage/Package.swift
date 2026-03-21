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
        .library(
            name: "AuthFeature",
            targets: ["AuthFeature"]
        ),
        .library(
            name: "SettingFeature",
            targets: ["SettingFeature"]
        ),
        .library(
            name: "HomeFeature",
            targets: ["HomeFeature"]
        ),
    ],
    dependencies: [
        .package(path: "../ProjectTools"),
        .package(url: "https://github.com/SwiftGen/SwiftGenPlugin", from: "6.6.2"),
        .package(url: "https://github.com/BarredEwe/Prefire.git", exact: "5.4.1")
    ],
    targets: [
        .target(
            name: "HometeDomain",
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
        .testTarget(
            name: "HometeDomainTests",
            dependencies: ["HometeDomain"],
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
            resources: [
                .process("Resources/Colors.xcassets"),
                .process("Resources/Image.xcassets"),
            ],
            plugins: [
                .plugin(name: "SwiftGenPlugin", package: "SwiftGenPlugin")
            ]
        ),
        .target(
            name: "AuthFeature",
            dependencies: [
                "HometeDomain",
                "HometeUI",
                "HometeResources",
            ],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
        .target(
            name: "SettingFeature",
            dependencies: [
                "HometeDomain",
                "HometeUI",
                "HometeResources",
            ],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
        .target(
            name: "HomeFeature",
            dependencies: [
                "HometeDomain",
                "HometeUI",
                "HometeResources",
                .product(name: "Prefire", package: "Prefire", condition: .when(platforms: [.iOS])),
            ],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
    ]
)
