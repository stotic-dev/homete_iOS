# Remote Config

> fetch・activateのタイミングと、キーごとの反映方針を決めた経緯は [ADR-0033](adr/0033-remote-config-fetch-and-per-key-apply-timing.md) を参照。

## パラメータ一覧

| キー | 型 | アプリ内デフォルト値 | 内容 | 反映タイミング |
|---|---|---|---|---|
| `ads_enabled` | Boolean | `false` | 広告表示を有効にするかどうか。プレミアム加入者には値によらず広告を出さない | 起動時のfetch完了時に確定し、起動中は変えない |

アプリ内デフォルト値は `RemoteConfigBoolKey.defaultValue`（`LocalPackage/Sources/HometeDomain/RemoteConfig/`）で定義している。キーを足すときは、コンソールへの登録とこの表の更新も併せて行う。

## アプリ側の挙動

| タイミング | 処理 |
|---|---|
| 起動時 | `fetchAndActivate()`（起動処理とは並行。完了を待たない） |
| バックグラウンドからの復帰時 | `fetchAndActivate()` |

- fetchのタイムアウトは3秒（リクエスト単位。初回はトークン取得が先に挟まるため、さらに遅れ得る）。失敗・タイムアウト時は前回activate済みの値、それも無ければアプリ内デフォルト値を使う
- `minimumFetchInterval` はReleaseが12時間、Debug/Stgが0秒。Releaseでは、コンソールで切り替えてから全ユーザーに届くまで最大12時間程度かかる
- Remote ConfigはApp Checkの保護対象外のため、デバッグトークンが無くてもfetchできる

## パラメータの作成・変更手順

stg（`homete-ios-dev-e3ef7`）→ prod（`homete-ios-dev`）の順に行う。プロジェクトIDは`-e3ef7`付きがSTG、付いていない方が本番。

1. Firebaseコンソールで対象プロジェクトを開き、**Remote Config** を選ぶ
2. **パラメータを追加**（既存なら該当パラメータの編集）で次を設定する
   - パラメータ名: `ads_enabled`
   - データ型: Boolean
   - デフォルト値: `false`（prodの初期値は現状維持の`false`）
3. **変更を公開** を押す。公開するまでアプリには配信されない
4. 動作確認
   - stg: TestFlightまたはXcodeから実行したビルドを再起動し、非プレミアムのアカウントで広告の表示・非表示が切り替わることを確認する
   - prod: App Store版は最大12時間程度かかるため、アプリの再インストールで即時に確認する（再インストールでfetchの最小間隔がリセットされる）

### 広告を緊急停止したいとき

`ads_enabled` を `false` にして公開する。起動中のアプリの広告は消えない。各端末でfetchがサーバーに問い合わせた後の起動から表示されなくなるため、Releaseでは全ユーザーに行き渡るまで最大12時間程度かかる。
