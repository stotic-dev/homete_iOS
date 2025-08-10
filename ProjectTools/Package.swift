// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProjectTools",
    products: [
        .library(
            name: "ProjectTools",
            targets: ["ProjectTools"]),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint.git", exact: "0.59.1")
    ],
    targets: [
        .target(
            name: "ProjectTools"),

    ]
)
