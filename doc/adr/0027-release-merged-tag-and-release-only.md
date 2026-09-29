## タイトル: リリースPRマージ時の自動処理をタグ作成とGitHub Release公開だけに絞る

* **ステータス: 承認済**
* 意思決定者: @stotic-dev
* 日付: 2026-09-29
* 技術的背景やその他関連チケット No: [ADR-0016](0016-release-pipeline-automation.md) の一部を置き換える

## 文脈、背景や問題点の説明

[ADR-0016](0016-release-pipeline-automation.md) では、リリースPRのmainマージをトリガーに `release-merged.yml` が「タグ作成 → GitHub Release publish → メタデータ同期 → Xcode Cloud起動」を直列で実行する構成にした。

v1.0.0のリリースで、このうちXcode Cloud起動のステップが失敗した（`XCODE_CLOUD_APPSTORE_WORKFLOW_ID` のシークレットが登録されておらず、`scripts/trigger-xcode-cloud-build.sh` に空のワークフローIDが渡った）。リリース自体は別の手段で完了していた。マージ時に自動で走らせたい処理は、実際にはタグ付けとGitHub Releaseの公開だけだった。

## 決定事項

* `release-merged.yml` が行う処理を「タグ作成・push」と「GitHub Release作成・publish」だけにする
* メタデータ同期（`sync-metadata.yml`）の起動と、Xcode Cloud「Upload For AppStore」の起動をワークフローから外す
  * `sync-metadata.yml` 自体は残し、必要なときに `workflow_dispatch` で手動実行する
* 呼び出し元がなくなった `scripts/trigger-xcode-cloud-build.sh` を削除する
* 起動するワークフローがなくなったので、`release-merged.yml` の `actions: write` 権限を外す

## 考慮した選択肢

* **シークレットを登録してADR-0016の構成を維持する**: マージからビルドのアップロードまで自動化できる。ただし、`ciBuildRuns` を作成する部分は一度も動作確認できておらず、自動化したい範囲でもないため採用しない
* **タグ作成とGitHub Release公開だけに絞る**: 採用

## 決定結果

### 決定にあたり考慮したメリット

* 動作確認できていないAPI呼び出しや、未登録のシークレットが原因でリリースワークフローが失敗しなくなる
* ワークフローが必要とするシークレット・権限が減る（ASC APIキー、`actions: write` が不要になる）

### 決定にあたり考慮したデメリット

* メタデータ同期とApp Storeへのビルドアップロードは手動で実行する必要がある。順序（メタデータ同期でASC上のバージョンを作ってからビルドをアップロードする等）も人が守る必要がある

## 参考

* [ADR-0016](0016-release-pipeline-automation.md)
* `.github/workflows/release-merged.yml`
* `.github/workflows/sync-metadata.yml`
