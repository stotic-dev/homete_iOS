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
    ],
    targets: [
        .target(
            name: "HometeDomain"
        ),
        .target(
            name: "HometeUI",
            dependencies: ["HometeDomain"]
        ),
        .testTarget(
            name: "HometeDomainTests",
            dependencies: ["HometeDomain"]
        ),
    ]
)
