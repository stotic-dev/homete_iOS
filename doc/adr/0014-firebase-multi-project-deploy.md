## Firebaseの本番デプロイ経路: `.firebaserc`をstg/prodの2エイリアスにし、本番は手動実行に限定する

* **ステータス: 承認済**
* 意思決定者: @stotic-dev
* 日付: 2026-08-31
* 技術的背景やその他関連チケット No: [#235](https://github.com/stotic-dev/homete_iOS/issues/235) / [#232](https://github.com/stotic-dev/homete_iOS/issues/232) / [#233](https://github.com/stotic-dev/homete_iOS/issues/233)

## 文脈、背景や問題点の説明

`firebase/.firebaserc` には `default: homete-ios-dev-e3ef7`（STG）しか定義されておらず、CIのデプロイワークフローも `--project` を指定せずこの `default` に暗黙依存していた。一方、App Store配信ビルド（`taichi.satou.hometekure`）が読む `GoogleService-Info.plist` の `PROJECT_ID` は別プロジェクト `homete-ios-dev` を指している。

結果として本番プロジェクトにはCloud Functions・Firestoreルール・Firestoreインデックスが一度もデプロイされておらず、プッシュ通知もアカウント削除時のデータ掃除も家事一覧のクエリも動かない。リリースブロッカーであり、「本番へ届く経路をどう作るか」と「作った経路で誤爆しないようにどう守るか」を同時に決める必要がある。

さらに、本番プロジェクトIDが `homete-ios-dev`、STGが `homete-ios-dev-e3ef7` という**どちらもdevに見える紛らわしい命名**になっている。プロジェクトIDは後から変更できないため、取り違えを設定側で防ぐ必要がある。

## 決定事項

* `.firebaserc` から `default` を削除し、`stg` / `prod` の2エイリアス構成にする

  ```json
  { "projects": { "stg": "homete-ios-dev-e3ef7", "prod": "homete-ios-dev" } }
  ```

* `default` を残さないことで、`--project` を書き忘れたコマンドは「暗黙にSTGへ飛ぶ」のではなく**エラーで落ちる**ようにする
* デプロイ・エミュレーター起動を含む全てのfirebaseコマンドで `--project` を明示する（`firebase/functions/package.json` の `serve` / `shell` / `deploy` / `logs` / `test:e2e` も `--project stg` を付与）
* `deploy-functions.yml` に `workflow_dispatch` の `environment` 入力（`stg` / `prod`、デフォルト `stg`）を追加する。`workflow_run` 経由の自動発火は入力が空になるためSTGにフォールバックし、**本番へは手動実行でしか到達しない**
* `deploy-firestore-indexes.yml` を `deploy-firestore.yml` にリネームし、インデックスに加えて `firestore.rules` も対象にする（`--only firestore:indexes,firestore:rules`）。トリガーも同様に環境選択式にする
* 本番用のサービスアカウントJSONは `FIREBASE_SERVICE_ACCOUNT_PROD` という別名のRepository Secretで管理する
* `concurrency` のグループを環境ごとに分け（`deploy-functions-stg` / `deploy-functions-prod`）、STGのデプロイが本番のデプロイをブロックしないようにする

## 考慮した選択肢

### 本番デプロイのトリガー

* **選択肢1: `release/*` ブランチへのpushで本番へ自動デプロイ**
  * リリース作業の手数が減る
  * ブランチの切り間違いがそのまま本番反映になる。`functions-e2e-test.yml` は既に `release/*` のpushで走るため、E2Eの成否と無関係にデプロイが走る導線も生まれる
* **選択肢2: `v*` タグのpushで本番へ自動デプロイ**
  * Xcode Cloudの `Upload For AppStore` が打つ `v{version}` タグに連動し、アプリ配信とFunctionsデプロイのタイミングが揃う
  * タグは archive 成功時に自動で打たれるため、Functionsを本番に出す判断とアプリをアップロードする判断が分離できない。ロールバックのために打ち直すタグでも再デプロイが走る
* **選択肢3: `workflow_dispatch` の環境選択のみ（採用）**
  * 本番反映が常に人の明示的な操作になる。現状のリリース頻度（月数回未満）では自動化の利得より誤爆の損失が大きい

### サービスアカウントSecretの管理

* **選択肢A: GitHub Environments（`stg` / `prod`）に同名のsecretを置く**
  * `environment:` を指定するだけで参照先が切り替わり、prodにReviewer必須の保護ルールを掛けられる
  * GitHub側でenvironmentを作る前提が増え、設定がリポジトリのコードから読み取れなくなる
* **選択肢B: `FIREBASE_SERVICE_ACCOUNT_PROD` という別名のRepository Secret（採用）**
  * GitHub側の追加作業がsecret登録だけで済む
  * secret名は式で動的に組み立てられないため、両方をstepの `env` に載せてシェルで選ぶ書き方になる

## 決定結果

### 決定にあたり考慮したメリット

* `default` が無いことで「`--project` の書き忘れ」がサイレントな誤爆ではなく即座のエラーになる。紛らわしいプロジェクトID命名に対する構造的な防御になっている
* 本番への経路が `workflow_dispatch` の1本に限られ、GitHubのActions実行履歴に「誰がいつ本番へ出したか」が残る
* STGへの自動デプロイ（`workflow_run` + E2E成功）という既存の挙動は変わらない。[ADR-0008](0008-deploy-functions-workflow.md) の前提を壊していない
* Firestoreルールのデプロイ経路が初めて用意され、[#233](https://github.com/stotic-dev/homete_iOS/issues/233) でルールを厳格化したときに実環境へ届くようになる

### 決定にあたり考慮したデメリット

* 本番デプロイが手動なので、mainにマージしただけでは本番に反映されない。リリース手順書に「Deploy Functions / Deploy Firestore を environment=prod で実行する」を明記して運用で担保する必要がある
* `environment` 入力は `stg` がデフォルトなので、本番のつもりで実行してSTGに出す取り違えは依然あり得る（逆方向の事故は防げているので、影響の小さい側に倒している）
* secret名を式で組み立てられない制約から、両環境のサービスアカウントJSONを常に1つのstepの `env` に載せる形になっている。ログへの出力は行っていないが、stepの実装を変更する際は注意が必要
* Firestoreルールとインデックスを1コマンドでまとめて反映するため、ルールだけ／インデックスだけの部分反映ができない
* `deploy-firestore-indexes.yml` をリネームしたため、この名前を参照するブランチ保護やAPI連携があれば追従が必要（現時点では参照なし）

## 本番プロジェクト側に必要な前提設定

コードだけでは完結せず、Firebase Console / GCP / GitHub 側での作業が必要。[ADR-0008](0008-deploy-functions-workflow.md) の「GCP側の前提設定」と同じものが本番プロジェクト `homete-ios-dev` にも必要になる。

* `FIREBASE_SERVICE_ACCOUNT_PROD` をGitHub Secretsに登録する
* そのサービスアカウントに **サービス アカウント ユーザー**（`roles/iam.serviceAccountUser`）を付与する。Functionsのデプロイは実行SA `homete-ios-dev@appspot.gserviceaccount.com` として `actAs` する操作を含むため必須（「サービス アカウント トークン作成者」では代替できない）
* Cloud Functions管理者・ストレージ管理者を付与する
* **Cloud Billing API** を有効化する（無効だとfirebase-toolsが有効化を試みて `Permissions denied enabling cloudbilling.googleapis.com` で落ちる）
* Firestoreのロケーションが `asia-northeast1`（`firebase.json` の指定）であることを確認する。ロケーションは作成後に変更できない
* `Houseworks.expiredAt` にTTLポリシーを設定する（STG側は [premium-housework-storage-period.md](../strategy/premium-housework-storage-period.md) で設定済み）
* APNs認証キー(.p8)を登録する（[#232](https://github.com/stotic-dev/homete_iOS/issues/232) と関連。未登録だと `notifyothercohabitants` の送信が失敗する）

なお本番へのルールデプロイは、[#233](https://github.com/stotic-dev/homete_iOS/issues/233) でセキュリティルールを最小権限に書き換えた**後**に実行すること。現在の `firestore.rules` は認証済みユーザーが全ドキュメントを読み書きできる状態のため、そのまま本番へ出すと脆弱性を本番に持ち込むことになる。

## 参考

* [ADR-0008: Functionsの自動デプロイ](0008-deploy-functions-workflow.md)
* `.github/workflows/deploy-functions.yml`
* `.github/workflows/deploy-firestore.yml`
* [Firebase CLI: プロジェクトエイリアス](https://firebase.google.com/docs/cli#project_aliases)
