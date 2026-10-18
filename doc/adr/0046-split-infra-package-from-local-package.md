## タイトル: 重い外部依存を持つモジュールをInfraPackageに切り出し、LocalPackageのユニットテストから外す

* **承認済**
* 意思決定者: stotic-dev
* 日付: 2026-10-17
* 関連: [ADR-0001](0001-spm-multimodule-structure.md)、[ADR-0029](0029-vrt-dedicated-host-app-target.md)、Issue #444

## 文脈、背景や問題点の説明

LocalPackageのユニットテスト（`make test-packages-fast` / `ci_local_package.yml`）は、テスト対象が
`HometeDomain`やFeatureだけでも、`HometeInfrastructure`が依存するFirebase・AdMob・UMP・RevenueCat・GRDBを
毎回解決・ビルドしていた。SwiftPMは依存をパッケージ単位で解決するため、テストターゲットがこれらに
依存していなくても、同じパッケージにある限りは避けられない。

外部SDKに依存しているのは`HometeInfrastructure`だけで、そこに依存しているのはアプリの組み立て役の`AppRoot`だけ。
どちらもユニットテストを持っていない。

## 決定事項

* `HometeInfrastructure`と`AppRoot`を、リポジトリ直下の新しいローカルパッケージ`InfraPackage`へ移す
* `InfraPackage`は`../LocalPackage`をパス依存で参照し、外部SDKの依存は`InfraPackage/Package.swift`だけに書く
* `HometeLocalNotification`はLocalPackageに残す。重い依存を持たず、Notification Service Extensionからも使うため
* `homete.xcodeproj`は`InfraPackage`をローカルパッケージとして追加し、`AppRoot`のプロダクトをそこから取る
* InfraPackageのビルドは、新しいワークフロー`ci_infra_package.yml`（`make build-infra-package`）で確認する。
  トリガーには`InfraPackage/**`に加えてLocalPackageのソース・マニフェストを含める

### InfraPackageのビルドをCIで別に確認する理由

切り出す前は、`swift test`がテストターゲットに無関係な`HometeInfrastructure`・`AppRoot`も一緒にビルドしていた。
そのため、`HometeDomain`のClientプロトコルやFeatureの公開APIを変えて実装側が追従していなければ、
ユニットテストのCIで落ちていた。

切り出した後は、何もしなければXcode Cloudに上げるまでこの種の不整合に気付けない。`AppRoot`は全Featureに
依存しているので、LocalPackageのソースが変わったときもInfraPackageをビルドする。

## 考慮した選択肢

* **現状のまま1パッケージにする**: 構成は単純だが、ユニットテストのたびに重い依存の解決とビルドが付いてくる
* **HometeInfrastructureだけを切り出す**: `AppRoot`はInfraに依存しているので、LocalPackageに残すと
  LocalPackageからInfraPackageを参照することになり、循環してしまう。`AppRoot`も一緒に移すしかない
* **InfraPackageに切り出す（採用）**

## 決定結果

LocalPackageが解決するパッケージは23個から6個（Prefire・swift-snapshot-testing・SwiftGenPluginと、
それらが推移的に依存するもの）に減った。Firebaseのgrpc・abseil・Firestoreなどのxcframeworkの取得と、
ソースからのビルドがユニットテストから外れる。

### 決定にあたり考慮したメリット

* ローカル・CIのユニットテストで、依存の解決とビルドが速くなる
* LocalPackageの`.build`が小さくなり、依存を取り直したときのやり直しも軽くなる
* 重い依存がどこにあるかが、パッケージの境界から一目で分かる

### 決定にあたり考慮したデメリット

* 管理するパッケージと`Package.resolved`が1つ増える。dependabotの監視対象とwtのフックにもInfraPackageを足している
* InfraPackageからLocalPackageへの依存が、パッケージをまたぐパス依存になる
* Domainの変更で実装側が追従していないと、ユニットテストではなく`infra_package_build`で落ちるようになる。
  ローカルで確かめるには`make build-infra-package`を別に流す必要がある
* Xcode Cloud（VRT）の依存解決は、これだけでは減らない。Xcodeはプロジェクト単位でパッケージを解決するので、
  `homete.xcodeproj`がInfraPackageを参照する限り取得される。VRT専用のプロジェクトに分けて解決した（[ADR-0047](0047-vrt-dedicated-xcode-project.md)）

## 参考

* [doc/multimodules_structure.md](../multimodules_structure.md)
