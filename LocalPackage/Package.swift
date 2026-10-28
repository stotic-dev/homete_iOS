// swift-tools-version: 6.2

import PackageDescription

// MARK: - Package

let package = Package(
    name: "LocalPackage",
    defaultLocalization: "ja",
    platforms: [.iOS(.v17), .macOS(.v26)],
    products: [
        lib("HometeModel"),
        lib("HometeDomain"),
        lib("HometeUI"),
        lib("HometeResources"),
        lib("AuthFeature"),
        lib("SettingFeature"),
        lib("HomeFeature"),
        lib("CohabitantRegistrationFeature"),
        lib("HouseworkFeature"),
        lib("ContributionFeature"),
        lib("HometeLocalNotification"),
        lib("HometeAppIntents"),
        lib("HouseworkTemplateFeature"),
        lib("FrequentHouseworkFeature"),
        lib("HometeSnapshotTestSupport")
    ],
    dependencies: [
        .package(path: "../ProjectTools"),
        .package(url: "https://github.com/SwiftGen/SwiftGenPlugin", from: "6.6.2"),
        .package(url: "https://github.com/BarredEwe/Prefire.git", exact: "6.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.19.6"),
    ],
    targets: [

        // MARK: Core Targets

        // UIが使う値型のドメインモデル。Store・UseCase・Clientは置かない（doc/adr/0063）
        .target(
            name: "HometeModel",
            resources: [localizableStrings()],
            plugins: [swiftLintPlugin()]
        ),
        .target(
            name: "HometeDomain",
            dependencies: ["HometeModel"],
            resources: [localizableStrings()],
            plugins: [swiftLintPlugin()]
        ),
        // HometeDomainには依存させない。Store・UseCase・Clientの変更でVRTが全件にならないようにする（doc/adr/0063）
        .target(
            name: "HometeUI",
            dependencies: [
                "HometeModel",
                "HometeResources",
                .product(name: "Prefire", package: "Prefire", condition: .when(platforms: [.iOS])),
            ],
            resources: [localizableStrings()],
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
        feature(name: "HomeFeature", extraDeps: ["ContributionFeature", "HouseworkFeature"]),
        feature(name: "CohabitantRegistrationFeature"),
        feature(name: "HouseworkFeature", extraDeps: ["FrequentHouseworkFeature"]),
        feature(name: "ContributionFeature"),
        feature(name: "FrequentHouseworkFeature"),

        // MARK: Others

        .target(
            name: "HouseworkTemplateFeature",
            dependencies: [
                "HometeDomain",
                "HometeUI",
                "HometeResources",
            ],
            path: "./Sources/Features/HouseworkTemplateFeature",
            resources: [localizableStrings()],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
        .testTarget(
            name: "HouseworkTemplateFeatureTests",
            dependencies: ["HouseworkTemplateFeature"],
            plugins: [
                .plugin(name: "SwiftLintPlugin", package: "ProjectTools"),
            ]
        ),
        // Notification Service Extensionからも使うため、Firebaseなど重い依存を持たせない
        .target(
            name: "HometeLocalNotification",
            dependencies: ["HometeDomain"],
            plugins: [swiftLintPlugin()]
        ),
        // Siri・Spotlight・ショートカットAppから実行するApp Intent。Firebaseの実装はアプリから受け取るため、
        // HometeInfrastructureに依存させない
        .target(
            name: "HometeAppIntents",
            dependencies: ["HometeDomain", "HouseworkFeature", "ContributionFeature"],
            resources: [localizableStrings()],
            plugins: [swiftLintPlugin()]
        ),

        // MARK: Test Support

        // VRT（hometeSnapshotTests）専用。アプリ本体からは依存しない
        .target(
            name: "HometeSnapshotTestSupport",
            dependencies: [
                .product(name: "Prefire", package: "Prefire", condition: .when(platforms: [.iOS])),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing", condition: .when(platforms: [.iOS])),
            ],
            plugins: [swiftLintPlugin()]
        ),

        // MARK: Test Targets

        .testTarget(
            name: "HometeModelTests",
            dependencies: ["HometeModel"],
            plugins: [swiftLintPlugin()]
        ),
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
        ),
        .testTarget(
            name: "SettingFeatureTests",
            dependencies: ["SettingFeature"],
            plugins: [swiftLintPlugin()]
        ),
        .testTarget(
            name: "FrequentHouseworkFeatureTests",
            dependencies: ["FrequentHouseworkFeature"],
            plugins: [swiftLintPlugin()]
        ),
        .testTarget(
            name: "HometeAppIntentsTests",
            dependencies: ["HometeAppIntents"],
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
        resources: [localizableStrings()],
        plugins: [swiftLintPlugin()]
    )
}

/// 画面に出す文言のString Catalog。キーは日本語の文言そのもので、英語などの訳はXcodeの「Generate Translation」で入れる
func localizableStrings() -> Resource {
    .process("Localizable.xcstrings")
}

func lib(_ name: String) -> Product {
    .library(name: name, targets: [name])
}
