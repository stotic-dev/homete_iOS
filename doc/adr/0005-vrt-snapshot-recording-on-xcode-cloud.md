## タイトル: VRT参照スナップショットの記録をローカルから Xcode Cloud へ移す

* **ステータス**: 承認済
* 意思決定者: taichisato（プロダクトオーナー）, Claude（調査担当）
* 日付: 2026-08-01
* 技術的背景: [ADR-0004](0004-vrt-snapshot-precision-tuning.md)（Xcode Cloud VRT の誤検出解消）の後続。記録環境と検証環境の分離という構造的問題への対応

## 文脈、背景や問題点の説明

現状、VRT（Prefire + swift-snapshot-testing）の参照PNG 216枚は**開発者がローカルの Mac で記録して commit する**運用になっている。検証は Xcode Cloud の `VRT` ワークフローが行う。

この「ローカルで記録し、CI で検証する」構成は、記録環境と検証環境が異なることを前提としており、[ADR-0004](0004-vrt-snapshot-precision-tuning.md) で解消した2つの誤検出（Display P3 と sRGB の色空間不一致、アンチエイリアスの ±1/255 丸め差）はいずれもこの分離に起因していた。ADR-0004 の対策（`displayGamut: .SRGB` 固定 + `perceptualPrecision` の 0.98 キャップ）は誤検出を抑えたが、環境差そのものは残っている。

さらに、**複数の開発者がそれぞれのローカル環境で記録するようになると、Mac の世代・macOS バージョン・ディスプレイのカラープロファイルの違いが参照PNGに混入し、誤検出の再発と原因調査コストが開発者数に比例して増える**。ADR-0004 が13回の試行を要したことを踏まえると、この運用コストは看過できない。

**記録そのものを CI 側に移し、差分は PR コメントで人間がレビューする方式（Android の Now in Android 的な運用）に切り替えられないか？**

## 決定事項

### 方針

* **参照スナップショットの記録を Xcode Cloud 上で行い、記録結果を PR ブランチに自動 commit する**。開発者はローカルで VRT を記録しない。
* **記録環境と検証環境を Xcode Cloud に一本化する**。GitHub Actions 側に VRT を二重に持たない。記録と検証が別環境になると ADR-0004 の問題がそのまま再発するため、これは必須条件とする。
* VRT の位置づけを**ゲート型（差分が出たら CI が落ちる）からレビュー型（差分を PR コメントで提示し、人間がレビューで承認する）に変更する**。

### 実装構成

1. **記録モードの注入**
   * `swift-snapshot-testing` は環境変数 `SNAPSHOT_TESTING_RECORD`（`all` / `failed` / `missing` / `never`）を読む（`AssertSnapshot.swift:76`）。
   * **`failed` を採用する。** 一致するものは書き換えず、不一致のものだけ上書き記録し、参照が存在しないものは新規記録する挙動のため、**git diff が「実際に見た目が変わったスナップショット」そのものになる**。
   * `hometeSnapshotTestsForCI.xctestplan` に `SNAPSHOT_TESTING_RECORD` を追加し、既存の `$(CI_XCODE_CLOUD)` と同じ方式で Xcode Cloud の環境変数から流し込む。

2. **記録モードでは XCTFail を抑止する**
   * `failed` モードでも `verifySnapshot` は失敗メッセージを返す。`generateTestTemplate.stencil` は戻り値を受けて自前で `XCTFail` を呼ぶ構造のため、記録モード時は `XCTFail` をスキップしてテストアクションを成功させる。
   * これは後述の「失敗時に `ci_post_xcodebuild.sh` が実行されない実測報告」への回避策であり、必須。

3. **`ci_post_xcodebuild.sh` で commit & push**
   * ガード条件: `CI_WORKFLOW` が記録用ワークフロー、`CI_XCODEBUILD_ACTION == "test-without-building"`（Xcode Cloud はテストを2回の xcodebuild に分割するため）、`CI_PULL_REQUEST_NUMBER` が存在、`CI_PULL_REQUEST_SOURCE_REPO == CI_PULL_REQUEST_TARGET_REPO`（fork 除外）。
   * 差分がなければ何もせず終了。差分があれば `[ci skip]` 付きでコミットし、`HEAD:refs/heads/$CI_PULL_REQUEST_SOURCE_BRANCH` へ push する。
   * push の認証は既存のタグ push（`ci_post_xcodebuild.sh:29-35`）と同じ `GITHUB_TOKEN` 方式を流用する。

4. **報告は既存の Danger をそのまま使う**
   * `DangerTools/Dangerfile.swift:15-58` が既に、PR で変更/追加された `__Snapshots__/PreviewTests.generated/*.png` について `raw.githubusercontent.com` の base/head SHA を使った before/after 画像比較テーブルを PR コメントに投稿する実装を持つ。
   * リポジトリが public のため raw URL がコメント内でそのままレンダリングされる。**報告側の新規実装は不要**。
   * bot の push は PAT 経由のため GitHub Actions の `pull_request: synchronize` が発火し、Danger が自動で走る。

5. **ループ対策は二重に掛ける**
   * コミットメッセージへの `[ci skip]`（Apple 公式サポート）
   * Pull Request Changes の Custom Conditions（ファイル/フォルダ条件）で `__Snapshots__` 配下以外のソース変更時のみ起動する

### 段階的な検証順序

一度に全部を入れず、以下の順で検証する。各段階が通ってから次に進む。

1. **書き込み可否の確認**: 既存 VRT ワークフローに `SNAPSHOT_TESTING_RECORD=failed` + XCTFail 抑止を入れ、**push はせず** `git status` をログ出力するだけの状態にする。シミュレータプロセスが `$CI_PRIMARY_REPOSITORY_PATH` 配下（`ci_scripts/__Snapshots__` シンボリックリンク経由）へ書き込めることを確認する。
2. **push の確認**: `git fetch --unshallow` の要否（shallow clone からの push が `shallow update not allowed` で拒否されないか）と、PR ブランチへの push 成否を確認する。
3. **ループ停止の確認**: `[ci skip]` と Custom Conditions によって、bot の push が新しい Xcode Cloud ビルドを起動しないことを確認する。

## 考慮した選択肢

* **現状維持（ローカル記録 + Xcode Cloud 検証）**: 開発者が増えるほど記録環境が分散し、ADR-0004 と同種の誤検出調査が繰り返される。運用コストが開発者数に比例して増える。
* **Xcode Cloud で記録（採用）**: 検証環境と記録環境が完全に一致する。既存の VRT ワークフロー・`ci_scripts`・Danger の資産をそのまま活かせ、新規に導入する CI 基盤がない。
* **GitHub Actions（`macos-26` standard runner）で記録**: リポジトリが public のため standard runner は無料・無制限。ワークフロー定義が git 管理下に入りレビュー可能、`if: always()` による失敗制御、`issue_comment` トリガーによるオンデマンド記録、同一ジョブ内での Danger 実行など運用面の自由度は高い。既に `ci_local_package.yml` が `macos-26` + Xcode 26.4.1 で稼働している実績もある。ただし、**Xcode Cloud に既にある VRT 資産を移設するコストと、iOS シミュレータ・Firebase 設定・SPM キャッシュのセットアップを新規に組む必要がある**ため、今回は採用しない。将来 Xcode Cloud のコンピュート時間が逼迫した場合、または fork PR 対応が必要になった場合の移行先候補として残す。

## 決定結果

### 決定にあたり考慮したメリット

* **記録環境と検証環境が完全に一致する。** ADR-0004 で扱った色空間不一致・丸め差といった環境差起因の誤検出が、構造的に発生しなくなる。
* 複数開発者になっても参照PNGの記録環境は Xcode Cloud 1つに固定されるため、**運用コストが開発者数に依存しなくなる**（本 ADR の主目的）。
* 開発者のローカルでの VRT 記録・再記録の手間がなくなる。ローカルは実装とユニットテストに集中できる。
* 差分の報告機構（Danger の before/after 画像テーブル）が**既に実装済み**であり、追加実装が不要。`SNAPSHOT_TESTING_RECORD=failed` により git diff が変更されたスナップショットと一致するため、コメントの内容が自然に「今回の PR で見た目が変わったもの」だけになる。
* 新規 Preview を追加した際の参照PNGも自動で記録・commit されるため、「記録し忘れによる CI 失敗」がなくなる。
* Xcode Cloud に閉じるため、新しい CI 基盤の追加・二重管理が発生しない。

### 決定にあたり考慮したデメリット

* **VRT が回帰の自動ゲートではなくなる。** 記録が自動で行われる以上、意図しない見た目の変化も自動で commit される。検出は「PR コメントの画像差分をレビュアーが見る」という人間の目に依存する。差分が多い PR ではレビューが形骸化するリスクがあり、PR を小さく保つ運用（既存の Danger 500行警告）との併用が前提になる。
* **fork からの PR では機能しない。** Xcode Cloud は fork PR に secret 環境変数を渡さず、push 先も他人のリポジトリになる。public リポジトリであるため、外部コントリビュータの PR では従来通り手動記録が必要になる。スクリプト側で fork を検出して無害にスキップする必要がある。
* **`ci_post_xcodebuild.sh` の失敗時実行が公式ドキュメントと実測で食い違う。** ドキュメントは「xcodebuild が失敗しても実行される」と明記しているが、[実際には実行されないという報告](https://developer.apple.com/forums/thread/803228)がある。XCTFail 抑止により通常フローは回避できるが、**コンパイルエラーでビルドが落ちた場合は記録も報告も行われない**。
* **Xcode Cloud のワークフロー定義が git 管理外**（App Store Connect の UI 設定）。Custom Conditions や環境変数の変更履歴が残らず、レビューもできない。ADR-0004 のような試行錯誤を再度行う場合、設定変更の記録は本 ADR や `doc/` に手動で残す必要がある。
* **オンデマンド記録ができない。** 「この差分は意図しないので記録し直したい／記録したくない」というケースで、PR コメントからのトリガー（`/record` 等）が作れない。App Store Connect API の `ciBuildRuns` を GitHub Actions から叩けば可能だが、ASC API キーの管理コストが増える。
* **コンピュート時間を圧迫する。** Apple Developer Program に含まれるのは 25 compute h/月、超過は $49.99/100h。VRT 1回を 15〜25分と見積もると月 60〜100 回で枯渇し、既存の `Upload Stg TestFlight` / `Upload For AppStore` ワークフローと食い合う。Custom Conditions による起動条件の絞り込みが実質的に必須。
* **auto-cancel がデフォルト有効**のため、連続 push 時に記録ビルドがキャンセルされる。PR の最新 push のみ記録されるので実害は小さいが、競合状態で古い記録が push される可能性は残る。
* **デバッグの反復が遅い。** スクリプト修正 → push → ビルド待ちのループになる。段階的な検証順序を定めたのはこの摩擦を最小化するため。

## 参考

* [ADR-0004: Xcode Cloud VRT（Prefireスナップショットテスト）の誤検出解消](0004-vrt-snapshot-precision-tuning.md)
* `hometeSnapshotTests/generateTestTemplate.stencil` — Prefire のテスト生成テンプレート（XCTFail 抑止の改修対象）
* `hometeSnapshotTestsForCI.xctestplan` — Xcode Cloud 用テストプラン（`SNAPSHOT_TESTING_RECORD` の追加先）
* `ci_scripts/ci_post_xcodebuild.sh` — commit & push の実装先。既存のタグ push が `GITHUB_TOKEN` 方式の実績
* `DangerTools/Dangerfile.swift` — before/after 画像比較コメントの実装（変更不要）
* swift-snapshot-testing `AssertSnapshot.swift` — `SNAPSHOT_TESTING_RECORD` の解決（L76）、`record == .failed` 時の再記録（L484）
* [Xcode Cloud environment variable reference](https://developer.apple.com/documentation/xcode/environment-variable-reference) — `CI_PULL_REQUEST_*`、`CI_XCODEBUILD_ACTION` 等
* [Configuring start conditions](https://developer.apple.com/documentation/xcode/configuring-start-conditions/) — Custom Conditions、`[ci skip]`
* [Writing custom build scripts](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts) — `ci_post_xcodebuild.sh` の実行タイミング
* [25 hours of Xcode Cloud now included with the Apple Developer Program](https://developer.apple.com/news/?id=ik9z4ll6)
