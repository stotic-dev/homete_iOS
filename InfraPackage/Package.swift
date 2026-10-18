// swift-tools-version: 6.2

import PackageDescription

// MARK: - Package

// Firebase・AdMob・RevenueCat・GRDBなど重い外部依存を持つモジュールだけを置く。
// LocalPackageのユニットテストがこれらを解決・ビルドしなくて済むよう、パッケージを分けている（ADR-0046）
let package = Package(
    name: "InfraPackage",
    defaultLocalization: "ja",
    platforms: [.iOS(.v17), .macOS(.v26)],
    products: [
        lib("HometeInfrastructure"),
        lib("AppRoot")
    ],
    dependencies: [
        .package(path: "../ProjectTools"),
        .package(path: "../LocalPackage"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "13.0.1"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "13.3.0"),
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-user-messaging-platform.git",
            from: "3.0.0"
        ),
        .package(url: "https://github.com/RevenueCat/purchases-ios-spm.git", from: "5.81.2"),
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "HometeInfrastructure",
            dependencies: [
                .product(name: "HometeDomain", package: "LocalPackage"),
                .product(name: "FirebaseAppCheck", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads", condition: .when(platforms: [.iOS])),
                .product(
                    name: "GoogleUserMessagingPlatform",
                    package: "swift-package-manager-google-user-messaging-platform",
                    condition: .when(platforms: [.iOS])
                ),
                .product(name: "RevenueCat", package: "purchases-ios-spm", condition: .when(platforms: [.iOS])),
                .product(name: "RevenueCatUI", package: "purchases-ios-spm", condition: .when(platforms: [.iOS])),
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            resources: [localizableStrings()],
            plugins: [swiftLintPlugin()]
        ),
        .target(
            name: "AppRoot",
            dependencies: [
                "HometeInfrastructure",
                localPackage("HometeDomain"),
                localPackage("HometeUI"),
                localPackage("AuthFeature"),
                localPackage("SettingFeature"),
                localPackage("HomeFeature"),
                localPackage("CohabitantRegistrationFeature"),
                localPackage("HouseworkFeature"),
                localPackage("HouseworkTemplateFeature"),
                localPackage("ContributionFeature"),
                localPackage("FrequentHouseworkFeature"),
                localPackage("HometeLocalNotification"),
                localPackage("HometeAppIntents")
            ],
            resources: [localizableStrings()],
            plugins: [swiftLintPlugin()]
        )
    ]
)

// MARK: - Helpers

func swiftLintPlugin() -> Target.PluginUsage {
    .plugin(name: "SwiftLintPlugin", package: "ProjectTools")
}

func localPackage(_ name: String) -> Target.Dependency {
    .product(name: name, package: "LocalPackage")
}

/// 画面に出す文言のString Catalog。キーは日本語の文言そのもので、英語などの訳はXcodeの「Generate Translation」で入れる
func localizableStrings() -> Resource {
    .process("Localizable.xcstrings")
}

func lib(_ name: String) -> Product {
    .library(name: name, targets: [name])
}
