// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// HometeUI・HometeResources はSwiftUI依存のためiOS・macOS以外では除外する
#if os(iOS) || os(macOS)
let iosOnlyDependencies: [Package.Dependency] = [
    .package(url: "https://github.com/SwiftGen/SwiftGenPlugin", from: "6.6.2")
]
let iosOnlyProducts: [Product] = [
    .library(
        name: "HometeUI",
        targets: ["HometeUI"]
    ),
    .library(
        name: "HometeResources",
        targets: ["HometeResources"]
    ),
]
let iosOnlyTargets: [Target] = [
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
]
#else
let iosOnlyDependencies: [Package.Dependency] = []
let iosOnlyProducts: [Product] = []
let iosOnlyTargets: [Target] = []
#endif

let package = Package(
    name: "LocalPackage",
    platforms: [.iOS(.v17), .macOS(.v15)],
    products: [
        .library(
            name: "HometeDomain",
            targets: ["HometeDomain"]
        ),
    ] + iosOnlyProducts,
    dependencies: [
        .package(path: "../ProjectTools"),
    ] + iosOnlyDependencies,
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
    ] + iosOnlyTargets
)
