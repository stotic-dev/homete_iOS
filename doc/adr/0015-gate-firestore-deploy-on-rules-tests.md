## Firestoreルールのデプロイ: ルールテストの通過を関門にし、同一ワークフロー内で直列に繋ぐ

* **ステータス: 承認済**
* 意思決定者: @stotic-dev
* 日付: 2026-09-05
* 技術的背景やその他関連チケット No: [#236](https://github.com/stotic-dev/homete_iOS/issues/236) / 前提: [#233](https://github.com/stotic-dev/homete_iOS/issues/233)（ルールのユニットテスト） / [#235](https://github.com/stotic-dev/homete_iOS/issues/235)（[ADR-0014](0014-firebase-multi-project-deploy.md) / デプロイ経路）

## 文脈、背景や問題点の説明

[ADR-0014](0014-firebase-multi-project-deploy.md) で `deploy-firestore.yml` を追加し、`firestore.rules` はmainへのpushでSTGへ、`workflow_dispatch` で本番へデプロイできるようになった。また #233 で `@firebase/rules-unit-testing` によるルールのユニットテスト（`firebase/functions/test/rules`）が入り、`functions-e2e-test.yml` で実行されるようになった。

しかしこの2つは繋がっていない。デプロイはテストの成否と無関係に走るため、ルールのテストが落ちていてもmainにマージされれば実環境へ反映される。Functionsは [ADR-0008](0008-deploy-functions-workflow.md) でE2E成功を前提にしたが、ルールは同じ保証がないまま残っていた。

ルールは壊れた内容を反映すると**全ユーザーがアプリを使えなくなる**（正規のリクエストまで拒否される）。逆に緩すぎれば情報漏洩に直結する。デプロイ前の検証をどう必須化するかを決める必要がある。

## 決定事項

* `deploy-firestore.yml` に `test-rules` ジョブを追加し、`deploy-firestore` ジョブを `needs: test-rules` にする
* `test-rules` はFirestore Emulatorを起動し、`firebase/functions/test/rules` のみを実行する（`firebase/functions/package.json` に `test:rules` スクリプトを追加）
* `workflow_dispatch` による本番デプロイも同じ関門を通す

## 考慮した選択肢

* **選択肢1: `deploy-functions.yml` と同じく `workflow_run` で `Firebase Functions E2E Test` の成功を受けて発火する（[ADR-0008](0008-deploy-functions-workflow.md) と同じ形）**
  * 既存のテスト実行をそのまま再利用でき、テストが二重に走らない
  * ただし2つの問題がある。1つは `deploy-firestore.yml` がインデックスも対象にしていること。`functions-e2e-test.yml` の `paths` に `firestore.indexes.json` は含まれないため、インデックスだけを変更するとデプロイが発火しなくなる
  * もう1つは**手動実行がテストを迂回すること**。`workflow_run` を関門にしても `workflow_dispatch` はそれを通らないため、最も慎重であるべき本番デプロイだけが無検証になる
* **選択肢2: 同一ワークフロー内に `test-rules` ジョブを置き `needs` で繋ぐ（採用）**
  * `push` / `workflow_dispatch` のどちらから来ても必ずテストを通る
  * `functions-e2e-test.yml` でも同じテストが走るため、ルール変更時は重複実行になる（Emulator起動込みで1〜2分程度）
* **選択肢3: ルールテストをFunctionsのパッケージから独立させ、専用パッケージ + 専用ワークフローにする**
  * ルール変更時のCIが軽くなり責務も分かれるが、#233 で `firebase/functions/test/rules` として実装済みのものを移設することになる
  * テストは `test/helpers/clientCollections.ts` をE2Eテストと共有しており、分離するとこの定義も重複する。得られるものに対して変更が大きい

## 決定結果

### 決定にあたり考慮したメリット

* mainへのpush・手動の本番デプロイのいずれも、ルールテストが緑でなければ反映されない。ブランチ保護やマージ順の運用に依存しない
* テストはリポジトリの `firestore.rules` を直接読み込むため、テストが検証したルールとデプロイされるルールが必ず一致する
* ジョブの依存関係が1ファイルで完結し、`workflow_run` のようにワークフロー名が暗黙の結合点にならない

### 決定にあたり考慮したデメリット

* ルールを変更したPRでは `functions-e2e-test.yml` と `deploy-firestore.yml` で同じルールテストが走る。実行時間の重複を受け入れている
* インデックスだけの変更でもルールテストが走り、デプロイまで1〜2分余分にかかる。インデックスとルールを別ワークフローに分ければ避けられるが、`firebase deploy --only firestore:indexes,firestore:rules` の1コマンドで済む利点を優先した
* `test-rules` はFunctionsのパッケージ（`npm ci`）に依存するため、ルールしか変えていなくてもFunctionsの依存インストールが必要になる

## 参考

* `.github/workflows/deploy-firestore.yml`
* `firebase/functions/test/rules/firestore.rules.test.ts`
* [ADR-0008](0008-deploy-functions-workflow.md) / [ADR-0014](0014-firebase-multi-project-deploy.md)
