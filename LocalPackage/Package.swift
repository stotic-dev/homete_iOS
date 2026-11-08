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
        lib("HometeAppCore"),
        lib("HometeUI"),
        lib("HometeResources"),
        lib("AuthFeature"),
        lib("AuthFeatureUI"),
        lib("SettingFeature"),
        lib("HomeFeature"),
        lib("CohabitantRegistrationFeature"),
        lib("CohabitantRegistrationFeatureUI"),
        lib("HouseworkFeature"),
        lib("ContributionFeature"),
        lib("ContributionFeatureUI"),
        lib("HometeLocalNotification"),
        lib("HometeAppIntents"),
        lib("HouseworkTemplateFeature"),
        lib("HouseworkTemplateFeatureUI"),
        lib("FrequentHouseworkFeature"),
        lib("FrequentHouseworkFeatureUI"),
        lib("PaywallFeature"),
        lib("PaywallFeatureUI"),
        lib("HometeSnapshotTestSupport")
    ],
    dependencies: [
        .package(path: "../ProjectTools"),
        .package(url: "https://github.com/SwiftGen/SwiftGenPlugin", from: "6.6.2"),
        .package(url: "https://github.com/BarredEwe/Prefire.git", exact: "6.5.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.19.7"),
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
        // 画面単位の状態と操作（Feature固有のStore・ViewModel）。SwiftUIには依存させない
        .target(
            name: "HometeAppCore",
            dependencies: ["HometeDomain"],
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

        feature(name: "AuthFeature", extraDeps: ["AuthFeatureUI"]),
        feature(name: "SettingFeature"),
        feature(name: "HomeFeature", extraDeps: ["ContributionFeature", "ContributionFeatureUI", "HouseworkFeature"]),
        feature(name: "CohabitantRegistrationFeature", extraDeps: ["CohabitantRegistrationFeatureUI"]),
        feature(name: "HouseworkFeature", extraDeps: ["FrequentHouseworkFeatureUI"]),
        feature(name: "ContributionFeature", extraDeps: ["ContributionFeatureUI"]),
        feature(name: "FrequentHouseworkFeature", extraDeps: ["FrequentHouseworkFeatureUI"]),
        feature(name: "PaywallFeature", extraDeps: ["PaywallFeatureUI"]),
        feature(name: "HouseworkTemplateFeature", extraDeps: ["HouseworkTemplateFeatureUI"]),

        // MARK: FeatureUI Targets

        featureUI(name: "CohabitantRegistrationFeatureUI"),
        featureUI(name: "FrequentHouseworkFeatureUI"),
        featureUI(name: "HouseworkTemplateFeatureUI"),
        featureUI(name: "ContributionFeatureUI"),
        featureUI(name: "AuthFeatureUI"),
        featureUI(name: "PaywallFeatureUI"),

        // MARK: Others

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
            dependencies: ["HometeDomain", "HouseworkFeature", "ContributionFeatureUI"],
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
            name: "HometeAppCoreTests",
            dependencies: ["HometeAppCore"],
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
            name: "SettingFeatureTests",
            dependencies: ["SettingFeature"],
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

/// UIのみのView（`XxxView` / `XxxContent`）とプレビューを置くモジュール。HometeDomainには依存させない（doc/adr/0063）
func featureUI(name: String, extraDeps: [Target.Dependency] = []) -> Target {
    .target(
        name: name,
        dependencies: ["HometeModel", "HometeUI", "HometeResources"] + extraDeps,
        path: "./Sources/Features/\(name)",
        resources: [localizableStrings()],
        plugins: [swiftLintPlugin()]
    )
}

func feature(name: String, extraDeps: [Target.Dependency] = []) -> Target {
    .target(
        name: name,
        dependencies: ["HometeDomain", "HometeAppCore", "HometeUI", "HometeResources"] + extraDeps,
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
