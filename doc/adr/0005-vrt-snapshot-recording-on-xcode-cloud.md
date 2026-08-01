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

3. **`ci_post_xcodebuild.sh` で自己呼び出し + commit & push**
   * **実測により判明した制約**: `test-without-building` action は `build-for-testing` とは別の使い捨てランナーで実行され、`$CI_PRIMARY_REPOSITORY_PATH` が空文字（gitチェックアウトが一切存在しない）。Apple公式フォーラムでも「テストを実行する環境にはソースコードがクローンされない」と明記されている（[thread 722923](https://developer.apple.com/forums/thread/722923)）。そのため `test-without-building` 側での記録・commit・pushは構造的に成立しない。
   * **採用する構成**: gitチェックアウトが存在する `build-for-testing` 側の `ci_post_xcodebuild.sh`（`CI_XCODEBUILD_ACTION == "build-for-testing"`）から、直前のビルドで生成済みの `-testProductsPath`（`/Volumes/workspace/TestProducts.xctestproducts`）を使い、`xcodebuild test-without-building` を自前で実行する。同一ランナー内で完結するため、`SNAPSHOT_TESTING_RECORD=failed` による書き込みがそのまま同じシェルのgit差分として検出できる（Build 212で実測確認済み）。
   * ガード条件: `CI_WORKFLOW` が記録用ワークフロー、`CI_XCODEBUILD_ACTION == "build-for-testing"`、`CI_PULL_REQUEST_NUMBER` が存在、`CI_PULL_REQUEST_SOURCE_REPO == CI_PULL_REQUEST_TARGET_REPO`（fork 除外）。
   * 差分がなければ何もせず終了。差分があれば `[ci skip]` 付きでコミットし、`HEAD:refs/heads/$CI_PULL_REQUEST_SOURCE_BRANCH` へ push する。新規（未追跡）ファイルも記録対象になるため、まず `git add` してから差分検出・commitする（`git diff --stat` は追跡済みファイルの変更のみを見るため、新規ファイルはこれだけでは検出できない点に注意。実測でも新規記録は `git status --short` の `??` としてのみ現れた）。
   * push の認証は既存のタグ push（`ci_post_xcodebuild.sh:29-35`）と同じ `GITHUB_TOKEN` 方式を流用する。
   * Xcode Cloud 公式の `test-without-building` action は引き続き別ランナーで実行される（現状は結果を使わずスキップするのみ）。記録自体は自己呼び出し側で完結するため機能上の問題はないが、コンピュート時間が二重に消費される。今後、ワークフロー構成の見直し（`test-without-building` の無効化など）を検討する。

4. **報告は既存の Danger をそのまま使う**
   * `DangerTools/Dangerfile.swift:15-58` が既に、PR で変更/追加された `__Snapshots__/PreviewTests.generated/*.png` について `raw.githubusercontent.com` の base/head SHA を使った before/after 画像比較テーブルを PR コメントに投稿する実装を持つ。
   * リポジトリが public のため raw URL がコメント内でそのままレンダリングされる。**報告側の新規実装は不要**。
   * bot の push は PAT 経由のため GitHub Actions の `pull_request: synchronize` が発火し、Danger が自動で走る。

5. **ループ対策は二重に掛ける**
   * コミットメッセージへの `[ci skip]`（Apple 公式サポート）
   * Pull Request Changes の Custom Conditions（ファイル/フォルダ条件）で `__Snapshots__` 配下以外のソース変更時のみ起動する

### 段階的な検証順序

一度に全部を入れず、以下の順で検証する。各段階が通ってから次に進む。

1. **書き込み可否の確認 ✅ 確認済み（Build 212, 2026-08-01）**: 当初は既存 `test-without-building` ワークフロー上での記録可否を検証する想定だったが、実測により当該ランナーには `$CI_PRIMARY_REPOSITORY_PATH` が空（gitチェックアウトが存在しない）ことが判明したため、`build-for-testing` ランナー上で `xcodebuild test-without-building` を自己呼び出しする構成（上記「実装構成」3.参照）に変更した。参照PNGを1枚意図的に削除した状態で push し、自己呼び出し実行後の `git status --short` にその新規ファイルが `??` として検出されることを確認した。
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
* [Apple Developer Forums thread 722923](https://developer.apple.com/forums/thread/722923) — 「テストを実行する環境にはソースコードがクローンされない」旨の公式回答。`test-without-building` ランナーでの記録・pushが構造的に成立しない根拠
* [Apple Developer Forums thread 716993](https://developer.apple.com/forums/thread/716993) — `test-without-building` 側からの参照アセット取り込み（読み込み専用）のワークアラウンド事例
* [jaanus.com: Snapshot testing on Xcode Cloud](https://jaanus.com/snapshot-testing-xcode-cloud/) — 参照PNGをSPMリソースとしてテストバンドルに同梱するアプローチ。`ci_scripts` シンボリックリンク方式を「過度に工夫された方法」と評する
