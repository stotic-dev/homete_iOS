## タイトル: リリースブランチへのメタデータ変更pushでApp Store Connectへの同期を自動実行する

* **ステータス: 承認済**
* 意思決定者: @stotic-dev
* 日付: 2026-10-01
* 技術的背景やその他関連チケット No: [ADR-0016](0016-release-pipeline-automation.md) / [ADR-0027](0027-release-merged-tag-and-release-only.md) の一部を置き換える

## 文脈、背景や問題点の説明

[ADR-0027](0027-release-merged-tag-and-release-only.md) で、リリースPRのマージ時にメタデータ同期（`sync-metadata.yml`）を走らせるのをやめ、必要なときに `workflow_dispatch` で手動実行する運用にした。

その結果、リリースPRに `fastlane/metadata/ja/release_notes.txt` などの更新を入れても、App Store Connect（以下ASC）への反映は人手の実行に依存するようになった。リリース作業の中で最も忘れやすく、忘れるとASC上の掲載文面が前バージョンのまま審査に出てしまう。一方でXcode Cloudの「Upload For AppStore」は既に `release/*` ブランチへのpushで起動しており、ビルドだけが自動で上がってメタデータだけ置いていかれる状態になっていた。

## 決定事項

* `sync-metadata.yml` に `push` トリガーを追加し、`release/**` ブランチへのpushのうち `fastlane/metadata/**` または `fastlane/screenshots/**` に変更があったものだけで起動する
* バージョンはブランチ名から解決する（`release/v1.1.0` → `1.1.0`）。`workflow_dispatch` / `workflow_call` の `version` 入力は従来どおり残し、Normalize versionステップで `release/` と先頭の `v` を剥がして共通化する
* 同一ブランチへの連続pushで `deliver` が並走しないよう `concurrency` を設定する。ASCへの反映途中で止めないため `cancel-in-progress: false` とする
* リリースPRマージ時（`release-merged.yml`）に同期を走らせない方針は [ADR-0027](0027-release-merged-tag-and-release-only.md) のまま維持する

## 考慮した選択肢

* **リリースPRマージ時（`release-merged.yml`）に戻す**: マージ = リリース確定なので実行タイミングとしては素直。ただしマージの影響範囲をタグとGitHub Releaseに限るという [ADR-0027](0027-release-merged-tag-and-release-only.md) の決定を丸ごと覆すことになる。またマージ後に気付いた文面修正はやはり手動実行が必要で、忘れやすさは解消しない
* **`pull_request` トリガーでベースが `release/*` のPRを見る**: PR上で同期できるが、マージ前の未確定な文面がASCに載る。fork PRでシークレットが使えない問題もある
* **`release/**` ブランチへのpush + pathsフィルタ**: 採用。Xcode Cloudの「Upload For AppStore」と起動条件が揃い、ビルドとメタデータが同じタイミングで上がる

## 決定結果

### 決定にあたり考慮したメリット

* リリースノートや掲載文面の更新をリリースPRに入れるだけでASCへ反映され、手動実行の忘れがなくなる
* ビルド（Xcode Cloud）とメタデータ（GitHub Actions）の起動条件が `release/*` へのpushで揃い、リリース作業の手順として覚えることが減る
* リリースブランチ作成時のpushは `homete.xcodeproj/project.pbxproj` の更新だけなので、pathsフィルタにより無駄な同期は走らない

### 決定にあたり考慮したデメリット

* リリースブランチ上で文面を何度も直すと、その都度ASCへ反映される（ASC側は編集可能なバージョンに対する上書きなので実害は小さいが、実行回数とmacOSランナーの消費は増える）
* スクリーンショットの更新でも起動するため、`deliver` の実行時間が長くなるケースがある
* ブランチ名がバージョンの唯一の情報源になるため、`release/` に続く形式が崩れるとNormalize versionで失敗する（形式チェックで検知はできる）

## 参考

* [ADR-0016](0016-release-pipeline-automation.md)
* [ADR-0027](0027-release-merged-tag-and-release-only.md)
* `.github/workflows/sync-metadata.yml`
* `.github/workflows/create-release-pr.yml`
