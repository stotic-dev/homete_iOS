## Functionsの自動デプロイ: E2E成功を条件にworkflow_runで発火させる

* **ステータス: 承認済**
* 意思決定者: @stotic-dev
* 日付: 2026-08-09
* 技術的背景やその他関連チケット No: [#192](https://github.com/stotic-dev/homete_iOS/issues/192) / [#202](https://github.com/stotic-dev/homete_iOS/pull/202)

## 文脈、背景や問題点の説明

Cloud FunctionsのデプロイはCIに存在せず、`make deploy`（= `firebase deploy --only functions`）の手動実行のみだった。そのためmainにマージしてもSTGには反映されず、反映漏れや「誰がいつ何を入れたか」が追えない状態になっていた。実際 Issue #192 の修正も、マージだけでは実環境の挙動が変わらない。

Firestoreインデックスは `deploy-firestore-indexes.yml` で自動デプロイされているので、Functionsも同様に自動化したい。ただしインデックスと違い、Functionsは壊れたコードがそのまま実行環境に載るため、デプロイ前の検証をどう担保するかを決める必要がある。

## 決定事項

* `deploy-functions.yml` を追加し、`firebase deploy --only functions --non-interactive` をCIから実行する
* 発火条件は `push` ではなく `workflow_run`（`Firebase Functions E2E Test` の完了）とし、**E2Eが成功したときだけ**デプロイする
* さらに `github.event.workflow_run.event == 'push'` と `head_branch == 'main'` を条件に加え、PR上のE2E成功では発火させない
* チェックアウトは `github.event.workflow_run.head_sha` を明示指定し、テストが通ったコミットそのものをデプロイする
* `concurrency: deploy-functions` でデプロイを直列化する
* 緊急時のために `workflow_dispatch` による手動実行も残す

## 考慮した選択肢

* **選択肢1: `deploy-firestore-indexes.yml` と同じく、mainへのpush + pathsで直接発火する**
  * 既存ワークフローと形が揃い、YAMLが最も単純
  * ただしテストの成否と無関係にデプロイされる。PRの必須チェックに頼る前提になり、squash mergeの取り違えや管理者マージで簡単に穴が開く
* **選択肢2: デプロイワークフロー内でE2Eも実行し、job間の `needs` で繋ぐ**
  * 依存関係が1ファイルで完結して読みやすい
  * `functions-e2e-test.yml` とジョブ定義がまるごと重複し、エミュレータ起動を含む数分のテストがmainへのpushで二重に走る
* **選択肢3: `workflow_run` でE2Eの成功を受けて発火する（採用）**

## 決定結果

### 決定にあたり考慮したメリット

* テストが緑のコミットしかSTGに出ないことをCIレベルで保証できる。ブランチ保護の設定に依存しない
* E2Eワークフローが `firebase/functions/**` のpathsで既に絞られているため、デプロイ側でpathsを二重管理しなくても対象変更時のみ動く
* テストの重複実行がなく、mainへのpush1回あたりのCI時間が増えない
* `head_sha` を明示チェックアウトするので、テスト実行後にmainが進んでも「検証していないコード」をデプロイしない
* `firebase.json` の predeploy がlintとbuildを実行するため、デプロイ直前にもう一段の検証が入る

### 決定にあたり考慮したデメリット

* `workflow_run` はデフォルトブランチ上のワークフロー定義でしか動かないため、このワークフロー自体の変更はmainにマージするまで実際の挙動を検証できない
* 発火元（`functions-e2e-test.yml`）の `name:` を変えると連鎖が黙って切れる。ワークフロー名が実質的な結合点になっている
* デプロイのトリガーが間接的になり、GitHubのUI上で「このpushがデプロイした」という繋がりが追いにくい（サマリにcommit SHAを出して緩和する）
* `FIREBASE_SERVICE_ACCOUNT` に Functions デプロイ相当の権限（Cloud Functions 管理者 / サービスアカウントユーザー / Cloud Build / Artifact Registry）が必要。インデックスデプロイ用の権限だけでは足りない可能性がある

## 参考

* [GitHub Actions: workflow_run](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_run)
* `.github/workflows/deploy-functions.yml`
* `.github/workflows/functions-e2e-test.yml`
* `.github/workflows/deploy-firestore-indexes.yml`
