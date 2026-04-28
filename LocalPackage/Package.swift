// swift-tools-version: 6.2

import PackageDescription

// MARK: - Package

let package = Package(
    name: "LocalPackage",
    platforms: [.iOS(.v17), .macOS(.v15)],
    products: [
        lib("HometeDomain"),
        lib("HometeUI"),
        lib("HometeResources"),
        lib("AuthFeature"),
        lib("SettingFeature"),
        lib("HomeFeature"),
        lib("HouseworkFeature"),
        lib("ContributionFeature"),
        lib("HometeInfrastructure"),
        lib("AppRoot")
    ],
    dependencies: [
        .package(path: "../ProjectTools"),
        .package(url: "https://github.com/SwiftGen/SwiftGenPlugin", from: "6.6.2"),
        .package(url: "https://github.com/BarredEwe/Prefire.git", exact: "5.4.1"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.0.0"),
    ],
    targets: [

        // MARK: Core Targets

        .target(
            name: "HometeDomain",
            plugins: [swiftLintPlugin()]
        ),
        .target(
            name: "HometeUI",
            dependencies: [
                "HometeDomain",
                "HometeResources",
                .product(name: "Prefire", package: "Prefire", condition: .when(platforms: [.iOS])),
            ],
            plugins: [swiftLintPlugin()]
        ),
        .target(
            name: "HometeResources",
            resources: [
                .process("Resources/Colors.xcassets"),
                .process("Resources/Image.xcassets"),
            ],
            plugins: [
                .plugin(name: "SwiftGenPlugin", package: "SwiftGenPlugin"),
            ]
        ),

        // MARK: Feature Targets

        feature(name: "AuthFeature"),
        feature(name: "SettingFeature"),
        feature(name: "HomeFeature", extraDeps: ["ContributionFeature"]),
        feature(name: "HouseworkFeature"),
        feature(name: "ContributionFeature"),

        // MARK: Infrastructure / Root

        .target(
            name: "HometeInfrastructure",
            dependencies: [
                "HometeDomain",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk", condition: .when(platforms: [.iOS])),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk", condition: .when(platforms: [.iOS])),
            ],
            plugins: [swiftLintPlugin()]
        ),
        .target(
            name: "AppRoot",
            dependencies: [
                "HometeDomain",
                "HometeUI",
                "AuthFeature",
                "SettingFeature",
                "HomeFeature",
                "HouseworkFeature",
                "ContributionFeature"
            ],
            plugins: [swiftLintPlugin()]
        ),

        // MARK: Test Targets

        .testTarget(
            name: "HometeDomainTests",
            dependencies: ["HometeDomain"],
            plugins: [swiftLintPlugin()]
        ),
        .testTarget(
            name: "HouseworkFeatureTests",
            dependencies: ["HouseworkFeature"],
            plugins: [swiftLintPlugin()]
        ),
        .testTarget(
            name: "ContributionFeatureTests",
            dependencies: ["ContributionFeature"],
            plugins: [swiftLintPlugin()]
        )
    ]
)

// MARK: - Helpers

func swiftLintPlugin() -> Target.PluginUsage {
    .plugin(name: "SwiftLintPlugin", package: "ProjectTools")
}

func feature(name: String, extraDeps: [Target.Dependency] = []) -> Target {
    .target(
        name: name,
        dependencies: ["HometeDomain", "HometeUI", "HometeResources"] + extraDeps,
        path: "./Sources/Features/\(name)",
        plugins: [swiftLintPlugin()]
    )
}

func lib(_ name: String) -> Product {
    .library(name: name, targets: [name])
}
