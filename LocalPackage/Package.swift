// swift-tools-version: 6.2

import PackageDescription

// MARK: - Package

// SwiftUI・UIKitで描くモジュールはUIPackageに置き、ここにはSwiftUIに依存しないモジュールとユニットテストだけを置く。
// CLI・行動テスト（AgentToolsPackage）からも使うため、AppleのUIフレームワークはimportしない（doc/adr/0071）
let package = Package(
    name: "LocalPackage",
    defaultLocalization: "ja",
    platforms: [.iOS(.v17), .macOS(.v26)],
    products: [
        lib("HometeModel"),
        lib("HometeDomain"),
        lib("HometeAppCore"),
        lib("HometeLocalNotification"),
        lib("HometeAppIntents"),
    ],
    dependencies: [
        .package(path: "../ProjectTools"),
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
        // 画面単位の状態と操作（Feature固有のStore・ViewModel）。iOSのUIとCLI・行動テストが同じものを使う（doc/adr/0071）
        .target(
            name: "HometeAppCore",
            dependencies: ["HometeDomain"],
            plugins: [swiftLintPlugin()]
        ),

        // MARK: Others

        // Notification Service Extensionからも使うため、Firebaseなど重い依存を持たせない
        .target(
            name: "HometeLocalNotification",
            dependencies: ["HometeDomain"],
            plugins: [swiftLintPlugin()]
        ),
        // Siri・Spotlight・ショートカットAppから実行するApp Intent。Firebaseの実装はアプリから受け取るため、
        // HometeInfrastructureに依存させない。結果をSwiftUIで描くIntentはUIPackageのHometeAppIntentsUIに置く
        .target(
            name: "HometeAppIntents",
            dependencies: ["HometeDomain", "HometeAppCore"],
            resources: [localizableStrings()],
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
            name: "HometeAppIntentsTests",
            dependencies: ["HometeAppIntents"],
            plugins: [swiftLintPlugin()]
        ),
    ]
)

// MARK: - Helpers

func swiftLintPlugin() -> Target.PluginUsage {
    .plugin(name: "SwiftLintPlugin", package: "ProjectTools")
}

/// 画面に出す文言のString Catalog。キーは日本語の文言そのもので、英語などの訳はXcodeの「Generate Translation」で入れる
func localizableStrings() -> Resource {
    .process("Localizable.xcstrings")
}

func lib(_ name: String) -> Product {
    .library(name: name, targets: [name])
}
