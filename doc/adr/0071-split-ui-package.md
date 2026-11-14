## タイトル: SwiftUIで描くモジュールをUIPackageに分け、LocalPackageをSwiftUIに依存させない

* **承認済**
* 意思決定者: stotic-dev
* 日付: 2026-11-14
* 関連: [ADR-0046](0046-split-infra-package-from-local-package.md)、[ADR-0048](0048-verify-only-affected-modules.md)、[ADR-0063](0063-split-ui-modules-from-domain-for-affected-vrt.md)、[ADR-0072](0072-app-core-view-models-and-behavior-cli.md)、Issue #515

## 文脈、背景や問題点の説明

LocalPackageには、値型・Store・UseCaseと、SwiftUIで描くHometeUI・Featureが同居していた。
`swift test`はテストが依存しないターゲットもビルドするため、UIもmacOS向けにコンパイルされ、iOSにしか無いAPIは`#if os(iOS)`で囲む必要があった。
また、画面ごとの状態と判断はFeatureの`XxxScreen`や、Featureに置いたStore（`ContributionStore`・`PaywallStore`など）にあり、
それらのテストもSwiftUIのモジュールに依存していた。ViewModelをシミュレーターなしでCLIから動かす（ADR-0072）には、
画面の状態と判断をSwiftUIに依存しないパッケージへ寄せる必要がある。

## 決定事項

* 新しく`UIPackage`を作り、SwiftUIで描くモジュールを移す。iOS向けにだけビルドし（`platforms: [.iOS(.v17)]`）、ユニットテストは置かない
  * `HometeUI`・`HometeResources`・`XxxFeature`・`XxxFeatureUI`・`HometeSnapshotTestSupport`
  * `HometeDomainUI`: `HometeDomain`をSwiftUIにつなぐ部分（`\.appDependencies`・`\.cohabitantMembers`・`\.isAdsEnabled`・`\.launchStateProxy`のEnvironment、
    `DependenciesInjectLayer`・`RouteResolver`・`.trackScreenView`）
  * `HometeAppIntentsUI`: Siriの結果をSwiftUIで描く`ShowContributionSummaryIntent`と、ドネーションの実装
* `LocalPackage`には、SwiftUI・UIKitに依存しない`HometeModel`・`HometeDomain`・`HometeAppCore`・`HometeLocalNotification`・`HometeAppIntents`と、ユニットテストだけを残す。外部の依存は持たない
* Featureに置いていた値型とテストはLocalPackageへ移す
  * UIが使う値型は`HometeModel`（例: `HouseworkBoardItem`・`TemplateItemEditInput`・`ContributionMonthlySummary`）
  * Feature固有のStoreと、Storeに依存する値型は`HometeAppCore`（例: `ContributionStore`・`PaywallStore`・`HouseworkTemplateEditStore`）
  * 見た目の属性（色など）を持っていたものは、属性だけ`XxxFeatureUI`のextensionに残す（`HouseworkItemMetaData`）
* 依存の向きは`InfraPackage → UIPackage → LocalPackage`。外部ライブラリ（SwiftGenPlugin・Prefire・swift-snapshot-testing）はUIPackageへ移す
* xcodeprojは`UIPackage`を参照する。VRT専用の`hometeVRT.xcodeproj`はLocalPackage・UIPackageだけを参照し、Firebaseを解決しない（ADR-0047のまま）
* `make build-ui-package`を足し、`make build-affected`・`scripts/affected-modules.py`はUIPackageのターゲットも判定・ビルドする

## 考慮した選択肢

* **UIをLocalPackageに置いたままにする**: 変更は少ないが、FeatureのStoreとテストがSwiftUIのモジュールに残り、CLIから使えない
* **Featureのテストだけ残してUIPackageもmacOS向けにビルドし続ける**: テストの移動は要らないが、UIをmacOS向けにコンパイルが通る形で書き続けることになり、画面の状態もCLIから届かない
* **UIのモジュールをUIPackageに分ける（採用）**

## 決定結果

### 決定にあたり考慮したメリット

* LocalPackageがSwiftUIに依存しないことを、パッケージの境界で守れる。CLI・行動テスト（AgentToolsPackage）はLocalPackageだけに依存できる
* UIはiOS向けのビルドだけを考えればよい
* LocalPackageは外部の依存を持たず、テストのための依存の解決が軽くなる

### 決定にあたり考慮したデメリット

* パッケージが増え、xcodeproj・Makefile・判定スクリプト・CIの参照先が増える
* UIPackageにはユニットテストが無く、GitHub ActionsではUIのコンパイルエラーが見つからない（以前はmacOS向けのテストのビルドがたまたまコンパイルしていた）。
  ローカルの`make build-affected`と、Xcode CloudのVRTのビルド、`ci_infra_package.yml`で見つける
* Feature固有の値型を`HometeModel`に寄せたため、それらを変えるとVRTの影響範囲が全件になる（ADR-0063の`HometeModel`と同じ扱い）
* `HometeAppIntents`の型の一部（`AppIntentEnvironment`など）を、`HometeAppIntentsUI`から使うためにpublicにした

## 参考

* [doc/multimodules_structure.md](../multimodules_structure.md)
* 参考にした構成: [rikugame-biyori-ios](https://github.com/stotic-dev/rikugame-biyori-ios) の ADR-0013
