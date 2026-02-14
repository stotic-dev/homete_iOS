// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LocalPackage",
    products: [
        .library(
            name: "HometeDomain",
            targets: ["HometeDomain"]
        ),
    ],
    targets: [
        .target(
            name: "HometeDomain"
        ),
        .testTarget(
            name: "HometeDomainTests",
            dependencies: ["HometeDomain"]
        ),
    ]
)
