// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProjectTools",
    platforms: [.macOS(.v10_15)],
    products: [
        .plugin(
            name: "SwiftLintPlugin",
            targets: ["SwiftLintPlugin"]
        ),
        .library(
            name: "ProjectToolsDummy",
            targets: ["ProjectToolsDummy"]
        ),
    ],
    targets: [
        .target(
            name: "ProjectToolsDummy"
        ),
        .plugin(
            name: "SwiftLintPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "SwiftLintPluginBinary"),
            ]
        ),
        .binaryTarget(
            name: "SwiftLintPluginBinary",
            url: "https://github.com/realm/SwiftLint/releases/download/0.59.1/SwiftLintBinary.artifactbundle.zip",
            checksum: "b9f915a58a818afcc66846740d272d5e73f37baf874e7809ff6f246ea98ad8a2"
        ),
    ]
)
