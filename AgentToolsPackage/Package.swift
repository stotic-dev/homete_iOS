// swift-tools-version: 6.2

import PackageDescription

// MARK: - Package

// AIエージェントがシミュレーターを起動せずにアプリの振る舞いを確かめるための道具を置く。
// HometeAppCoreのViewModelの状態と操作をJSONで公開し、CLIと行動テストから同じ入口で動かす（doc/adr/0072）。
// ホスト（macOS）向けにだけビルドする。UIPackage・InfraPackageには依存しない
let package = Package(
    name: "AgentToolsPackage",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "HometeIntrospection", targets: ["HometeIntrospection"]),
        .library(name: "HometeScenarioSupport", targets: ["HometeScenarioSupport"]),
        .executable(name: "homete-cli", targets: ["HometeCLI"]),
    ],
    dependencies: [
        .package(path: "../ProjectTools"),
        .package(path: "../LocalPackage"),
    ],
    targets: [
        // 今の画面・状態・実行できる操作をJSONにし、JSONの操作をViewModelのActionへ渡す。
        // 業務ロジックや画面の分岐はここに書かず、ViewModelに任せる
        .target(
            name: "HometeIntrospection",
            dependencies: [
                localPackage("HometeAppCore"),
                localPackage("HometeDomain"),
            ],
            plugins: [swiftLintPlugin()]
        ),
        // シナリオごとに独立した保存先（fixture）を作り、成功・失敗を外部依存の境界で制御する
        .target(
            name: "HometeScenarioSupport",
            dependencies: [
                "HometeIntrospection",
                localPackage("HometeAppCore"),
                localPackage("HometeDomain"),
            ],
            plugins: [swiftLintPlugin()]
        ),
        // 標準入力の1行ごとのコマンドを受け、標準出力へJSONを1行ずつ返す。診断は標準エラー出力へ出す
        .executableTarget(
            name: "HometeCLI",
            dependencies: [
                "HometeIntrospection",
                "HometeScenarioSupport",
            ],
            plugins: [swiftLintPlugin()]
        ),
        // Introspection・ViewModelを通した行動テストと、CLIのプロセスのJSONの入出力のテスト
        .testTarget(
            name: "HometeBehaviorTests",
            dependencies: [
                "HometeIntrospection",
                "HometeScenarioSupport",
                localPackage("HometeAppCore"),
                localPackage("HometeDomain"),
                // CLIのプロセスを起動するテストのため、実行ファイルを先にビルドさせる
                "HometeCLI",
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
