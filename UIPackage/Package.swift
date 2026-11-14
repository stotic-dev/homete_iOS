// swift-tools-version: 6.2

import PackageDescription

// MARK: - Package

// SwiftUIで描くモジュール。iOS向けにだけビルドし、ユニットテストは置かない（doc/adr/0071）。
// 画面の状態と判断はLocalPackageのHometeAppCore・HometeDomainに置き、ここではつなぐだけにする
let package = Package(
    name: "UIPackage",
    defaultLocalization: "ja",
    platforms: [.iOS(.v17)],
    products: [
        lib("HometeDomainUI"),
        lib("HometeUI"),
        lib("HometeResources"),
        lib("AuthFeature"),
        lib("AuthFeatureUI"),
        lib("SettingFeature"),
        lib("SettingFeatureUI"),
        lib("HomeFeature"),
        lib("HomeFeatureUI"),
        lib("CohabitantRegistrationFeature"),
        lib("CohabitantRegistrationFeatureUI"),
        lib("HouseworkFeature"),
        lib("HouseworkFeatureUI"),
        lib("ContributionFeature"),
        lib("ContributionFeatureUI"),
        lib("HouseworkTemplateFeature"),
        lib("HouseworkTemplateFeatureUI"),
        lib("FrequentHouseworkFeature"),
        lib("FrequentHouseworkFeatureUI"),
        lib("PaywallFeature"),
        lib("PaywallFeatureUI"),
        lib("HometeAppIntentsUI"),
        lib("HometeSnapshotTestSupport"),
    ],
    dependencies: [
        .package(path: "../ProjectTools"),
        .package(path: "../LocalPackage"),
        .package(url: "https://github.com/SwiftGen/SwiftGenPlugin", from: "6.6.2"),
        .package(url: "https://github.com/BarredEwe/Prefire.git", exact: "6.5.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.19.7"),
    ],
    targets: [

        // MARK: Core Targets

        // HometeDomainをSwiftUIにつなぐ部分（Environmentへの登録・DependenciesInjectLayer・RouteResolver・画面計測）
        .target(
            name: "HometeDomainUI",
            dependencies: [localPackage("HometeDomain")],
            plugins: [swiftLintPlugin()]
        ),
        // HometeDomainには依存させない。Store・UseCase・Clientの変更でVRTが全件にならないようにする（doc/adr/0063）
        .target(
            name: "HometeUI",
            dependencies: [
                localPackage("HometeModel"),
                "HometeResources",
                .product(name: "Prefire", package: "Prefire"),
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
        feature(name: "HouseworkFeature", extraDeps: ["FrequentHouseworkFeatureUI"]),
        feature(name: "ContributionFeature"),
        feature(name: "FrequentHouseworkFeature"),
        feature(name: "PaywallFeature"),
        feature(name: "HouseworkTemplateFeature"),

        // MARK: FeatureUI Targets

        featureUI(name: "AuthFeatureUI"),
        featureUI(name: "SettingFeatureUI"),
        featureUI(name: "HomeFeatureUI", extraDeps: ["ContributionFeatureUI", "HouseworkFeatureUI"]),
        featureUI(name: "CohabitantRegistrationFeatureUI"),
        featureUI(name: "HouseworkFeatureUI", extraDeps: ["FrequentHouseworkFeatureUI"]),
        featureUI(name: "ContributionFeatureUI"),
        featureUI(name: "FrequentHouseworkFeatureUI"),
        featureUI(name: "PaywallFeatureUI"),
        featureUI(name: "HouseworkTemplateFeatureUI"),

        // MARK: Others

        // Siriの結果をSwiftUIで描くApp Intent。それ以外のIntentはLocalPackageのHometeAppIntentsに置く
        .target(
            name: "HometeAppIntentsUI",
            dependencies: [localPackage("HometeAppIntents"), localPackage("HometeDomain"), "ContributionFeatureUI"],
            resources: [localizableStrings()],
            plugins: [swiftLintPlugin()]
        ),

        // MARK: Test Support

        // VRT（hometeSnapshotTests）専用。アプリ本体からは依存しない
        .target(
            name: "HometeSnapshotTestSupport",
            dependencies: [
                .product(name: "Prefire", package: "Prefire"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            plugins: [swiftLintPlugin()]
        ),
    ]
)

// MARK: - Helpers

func swiftLintPlugin() -> Target.PluginUsage {
    .plugin(name: "SwiftLintPlugin", package: "ProjectTools")
}

func localPackage(_ name: String) -> Target.Dependency {
    .product(name: name, package: "LocalPackage")
}

/// UIのみのView（`XxxView` / `XxxContent`）とプレビューを置くモジュール。HometeDomainには依存させない（doc/adr/0063）
func featureUI(name: String, extraDeps: [Target.Dependency] = []) -> Target {
    .target(
        name: name,
        dependencies: [localPackage("HometeModel"), "HometeUI", "HometeResources"] + extraDeps,
        path: "./Sources/Features/\(name)",
        resources: [localizableStrings()],
        plugins: [swiftLintPlugin()]
    )
}

/// ロジックを持つView（`XxxScreen` / `XxxComponent`）を置くモジュール。同じ名前の`XxxFeatureUI`に依存する
func feature(name: String, extraDeps: [Target.Dependency] = []) -> Target {
    .target(
        name: name,
        dependencies: [
            .target(name: "\(name)UI"),
            localPackage("HometeDomain"),
            localPackage("HometeAppCore"),
            "HometeDomainUI",
            "HometeUI",
            "HometeResources",
        ] + extraDeps,
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
