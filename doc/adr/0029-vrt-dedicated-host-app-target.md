## タイトル: VRT専用のホストアプリターゲットを用意してスナップショットテストのビルド時間を削る

* **承認済**
* 意思決定者: stotic-dev
* 日付: 2026-09-30
* 関連: [ADR-0001](0001-spm-multimodule-structure.md)

## 文脈、背景や問題点の説明

VRT（Prefire + swift-snapshot-testing）のテストホストが`homete`アプリターゲットだったため、
スナップショットを1枚撮るためだけに `AppRoot → HometeInfrastructure → firebase-ios-sdk /
GoogleMobileAds / RevenueCat` の全体をビルドする必要があった。firebase-ios-sdkはSPM経由だと
gRPC・abseil・leveldbをソースからビルドするため、Xcode Cloudの`VRT`ワークフローの所要時間の
大半がスナップショットと無関係なコンパイルに費やされていた。

一方、スナップショット対象のViewが属する`Features` / `HometeUI` / `HometeDomain` /
`HometeResources` は、`LocalPackage/Package.swift` 上でこれらのライブラリに一切依存していない。

## 決定事項

* スナップショットテスト専用のアプリターゲット `hometeVRTHost` を `homete.xcodeproj` に追加し、
  `hometeSnapshotTests` の `TEST_HOST` / `BUNDLE_LOADER` をこちらへ向ける
* `hometeVRTHost` は key window を用意するだけの空の`App`とし、LocalPackageには依存させない
* 描画対象のモジュール（HometeDomain / HometeResources / HometeUI と各Feature）は
  `hometeSnapshotTests` 側が直接リンクする
* `AppRoot` はVRTの対象から外す。唯一スナップショットを持っていた `LaunchScreenView` は
  `HometeUI` へ移動して維持する（`AppTabView`のプレビューは`.prefireIgnored()`済み）

### ホストではなくテストバンドルにリンクさせた理由

`@testable import`したシンボルをホストアプリ経由（`-bundle_loader`）で解決させる場合、
ホストが参照していないオブジェクトファイルは静的リンク時に取り込まれない可能性がある。
従来は`AppRoot`が全Featureを実際に使っていたため成立していたが、空のホストでは成立が保証できない。
テストバンドル側でリンクすれば、Prefireが生成するテストコードが各プレビューを明示的に参照するため、
必要なシンボルは必ず取り込まれる。

### ローカライズの扱い

`homete.app` は `Localizable.xcstrings` のコンパイル結果として `ja.lproj` を持つため、
`-AppleLanguages (ja)` を渡すと `Locale.current` が ja に解決される。`hometeVRTHost` は
文字列カタログを持たないので、`Info.plist` の `CFBundleLocalizations` で `ja` / `en` を明示して
同じ状態を作る。既存の `Localizable.xcstrings` は全エントリが `stale` かつ訳文がキーと同一で、
表示される文字列には影響しない。

## 考慮した選択肢

* **VRT専用のホストアプリターゲットを追加する（採用）**
* **VRT専用に別プロジェクト（`.xcodeproj`）を切る** — ビルドされるのはスキームの依存グラフ内だけなので
  高速化の効果は同じである一方、`.xcworkspace` の新設とXcode Cloud側の設定変更が増える
* **Xcode 27.2のJSONプロジェクト形式（`project.xcproj`）で新規プロジェクトを作る** — 作成・変換に
  Xcode 27.2が必要で、2026-09-30時点ではbeta（安定版は27.0）。Xcode CloudやCocoaPods/Xcodeproj・
  tuist/XcodeProjなど周辺ツールの対応も揃っていないため見送る。安定版が出た時点で
  プロジェクト全体の変換として別途検討する
* **現状維持（hometeをホストのまま使う）**

## 決定結果

### 決定にあたり考慮したメリット

* VRTの依存グラフから firebase-ios-sdk / GoogleMobileAds / RevenueCat のコンパイル・リンクが外れる
* `ci_scripts/ci_post_clone.sh` の`VRT`分岐で `Secret_dev.xcconfig` をデコードする必要がなくなる。
  これはGoogle Mobile Ads SDKがリンクされているせいで `GADApplicationIdentifier` 未定義だと
  起動時にクラッシュするための回避策だった
* VRTがFirebase設定・広告設定の状態に左右されなくなり、失敗の原因がUIの差分に絞られる

### 決定にあたり考慮したデメリット

* アプリターゲットが1つ増え、`homete` と `hometeVRTHost` でビルド設定の二重管理が生じる。
  ただしVRTホストが持つのは起動に最低限必要な設定のみで、機能追加に伴う変更は基本的に発生しない
* スナップショット対象のモジュールを増やしたときに、`.prefire.yml` の `testable_imports` と
  `hometeSnapshotTests` のリンク設定の両方を更新する必要がある
* `AppRoot` 配下のViewはVRTの対象外になる。対象にしたい場合は `HometeUI` か Feature へ移す

### 前提

* SPMのパッケージ「解決」は `LocalPackage/Package.swift` の `dependencies` 全件に対して走るため、
  firebase-ios-sdk などの取得時間自体は残る。ここまで削るには `HometeInfrastructure` を
  別パッケージへ切り出す必要があり、本ADRの範囲外とする
* Xcode Cloudの`VRT`ワークフローが `hometeSnapshotTests` スキームを使っていることが前提。
  `homete` スキームを使っている場合は `homete.app` がビルドされ続けるため効果が出ない

## 実測結果（2026-09-30）

Xcode Cloud の `VRT` ワークフローで比較した（変更前 Build 548 / 変更後 Build 559）。

| | 変更前 | 変更後 |
|---|---|---|
| ビルドしたターゲット数 | 105 | **19** |
| ビルド（build-for-testing） | 80秒 | **40秒** |
| パッケージ解決 | 62秒 | 62秒 |
| テスト成果物（TEST_PRODUCTS） | 76.6 MiB | **26.4 MiB** |
| アクション間の受け渡し | 88秒 | **72秒** |
| テスト実行（220テスト）× 2 | — | 74.0秒 / 73.1秒 |
| テスト1回あたりの起動オーバーヘッド | 42.7秒 | 44.9秒 |
| VRT全体 | 11分34秒 | **9分46秒** |

Firebase・gRPC・abseil・BoringSSL・leveldb・GoogleMobileAds・RevenueCat・AppRoot・
HometeInfrastructure がビルド対象から完全に消えた。

ただし**Xcode Cloud上での短縮幅は限定的**だった。Xcode Cloud はビルド成果物をキャッシュして
いるため、Firebaseのビルドは変更前でも80秒しかかかっていない。当初想定した「Firebaseの
コンパイルが支配的」はXcode Cloudには当てはまらない。

一方**ローカルでは効果が大きい**。キャッシュが無い状態では gRPC・abseil・leveldb を
ソースからビルドし直すため、その分が丸ごと消える。ローカル実測は `build-for-testing` が
コールドで69秒、テストバンドル29MB。

### 参照スナップショットをテストバンドルへコピーしない方法

`hometeSnapshotTests/__Snapshots__` の参照PNG 61MB が `.xctest` バンドルへコピーされていた
（`CopyPNGFile` 884件）。参照画像はバンドルから読まれないため完全な死荷重で、テスト成果物を
76.6 MiB に膨らませ、build-for-testing → test-without-building の受け渡しを重くしていた。

**Xcode 27では、file-system synchronized group 配下のリソースに対して次の2つはどちらも効かない**
（Build 553 / 554 で実測。`CopyPNGFile` が884件のまま、成果物サイズも変化なし）。

- `PBXFileSystemSynchronizedBuildFileExceptionSet` の `membershipExceptions` にディレクトリ名を並べる
- テストターゲットの `EXCLUDED_SOURCE_FILE_NAMES` にパターンを指定する（ビルドログに痕跡すら出ない）

効いたのは**同期グループの範囲自体を狭める**方法。グループの `path` を
`hometeSnapshotTests/Sources` にして、`__Snapshots__` をグループの外に出す。

`__Snapshots__` の場所は動かしていないので、`ci_scripts/__Snapshots__` のシンボリックリンク、
`ci_scripts/*.sh` のパス、`DangerTools/Dangerfile.swift` の参照先はいずれも変更不要。
884ファイルを `git mv` する案を採らなかったのは、`danger.git.createdFiles` にリネーム先が
全件入り、Dangerが before/after 画像表を884個投稿してしまうため。

生成ファイルが `Sources/` 配下へ移ることで `verifySnapshot` のデフォルト（`#filePath` 基準の
`__Snapshots__`）が `Sources/__Snapshots__` を指してしまうので、stencilの
`snapshotDirectoryOverride` をローカルでも明示的に返すようにした。

### テストの二重実行は意図的なもの

VRTはスナップショットテストを2回実行する（[ADR-0005](0005-vrt-snapshot-recording-on-xcode-cloud.md)）。
1回目は `ci_post_xcodebuild.sh` 内の record モードで参照を更新してコミットし、2回目のXcode Cloud
公式アクションが記録済みの参照と突き合わせて検証する。**1回目と2回目で描画が揺れるフレーキーな
スナップショットをここで落とせる**ため、実行時間の短縮を理由に一本化してはならない。

テスト1回あたり「起動オーバーヘッド約45秒 + テスト実行約74秒」がかかり、これが2回分ある。
起動オーバーヘッドはテストバンドルを76.6 MiB→26.4 MiB に縮めても変わらなかった
（42.7秒→44.9秒）ので、`xcodebuild test-without-building` の固定コストであり、
ローカルでも同じ35〜45秒が再現する。

## 参考

* [Xcodeの新しいJSONプロジェクト形式（Sarunw）](https://sarunw.com/posts/xcode-json-project-format-xcproj/)
* [Xcode 27.2 Beta Release Notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes)
