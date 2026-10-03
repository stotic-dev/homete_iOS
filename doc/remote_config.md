# Remote Config

> fetch・activateのタイミングと、キーごとの反映方針を決めた経緯は [ADR-0033](adr/0033-remote-config-fetch-and-per-key-apply-timing.md) を参照。
> 強制アップデートの判定・表示方式とリアルタイム更新を採用した経緯は [ADR-0034](adr/0034-force-update-with-realtime-remote-config.md) を参照。

## パラメータ一覧

| キー | 型 | アプリ内デフォルト値 | 内容 | 反映タイミング |
|---|---|---|---|---|
| `ads_enabled` | Boolean | `false` | 広告表示を有効にするかどうか。プレミアム加入者には値によらず広告を出さない | 起動時のfetch完了時に確定し、起動中は変えない |
| `minimum_required_version` | String | `""`（ブロックしない） | これより古いバージョンは強制アップデート画面で利用を止める（例: `1.4.0`）。空・不正な値ならブロックしない | 値を反映するたびに判定し直す（起動中も即時） |
| `force_update_message` | String | `""`（アプリ内の文言） | 強制アップデート画面の本文。空ならアプリ内の文言を表示する | `minimum_required_version`と同じ |

アプリ内デフォルト値は `RemoteConfigBoolKey.defaultValue` / `RemoteConfigStringKey.defaultValue`（`LocalPackage/Sources/HometeDomain/RemoteConfig/`）で定義している。キーを足すときは、コンソールへの登録とこの表の更新も併せて行う。

## アプリ側の挙動

| タイミング | 処理 |
|---|---|
| 起動時 | `fetchAndActivate()`（起動処理とは並行。完了を待たない） |
| バックグラウンドからの復帰時 | `fetchAndActivate()` |
| コンソールで変更を公開したとき（フォアグラウンド中のみ） | リアルタイム更新を受け取ってactivateする（`minimumFetchInterval`に関係なく届く） |

- fetchのタイムアウトは3秒（リクエスト単位。初回はトークン取得が先に挟まるため、さらに遅れ得る）。失敗・タイムアウト時は前回activate済みの値、それも無ければアプリ内デフォルト値を使う
- `minimumFetchInterval` はReleaseが12時間、Debug/Stgが0秒。Releaseでは、コンソールで切り替えてから全ユーザーに届くまで最大12時間程度かかる
- Remote ConfigはApp Checkの保護対象外のため、デバッグトークンが無くてもfetchできる
- リアルタイム更新は、Google Cloudの「Firebase Remote Config Realtime API」が有効なプロジェクトでだけ届く。公開しても起動中の端末に反映されない場合は、対象プロジェクトでこのAPIが有効か確認する（無効でも、復帰時のfetchで追いつく）

## パラメータの作成・変更手順

stg（`homete-ios-dev-e3ef7`）→ prod（`homete-ios-dev`）の順に行う。プロジェクトIDは`-e3ef7`付きがSTG、付いていない方が本番。

1. Firebaseコンソールで対象プロジェクトを開き、**Remote Config** を選ぶ
2. **パラメータを追加**（既存なら該当パラメータの編集）で次を設定する
   - `ads_enabled`: データ型 Boolean、デフォルト値 `false`（prodの初期値は現状維持の`false`）
   - `minimum_required_version`: データ型 String、デフォルト値は空文字（「空の文字列」を選ぶ）
   - `force_update_message`: データ型 String、デフォルト値は空文字
3. **変更を公開** を押す。公開するまでアプリには配信されない
4. 動作確認
   - stg: TestFlightまたはXcodeから実行したビルドを再起動し、非プレミアムのアカウントで広告の表示・非表示が切り替わることを確認する
   - prod: App Store版は最大12時間程度かかるため、アプリの再インストールで即時に確認する（再インストールでfetchの最小間隔がリセットされる）

### 強制アップデートをかけたいとき

1. 対象のバージョンより新しいバージョンがApp Storeで配信済みであることを確認する（未配信のまま公開すると、アップデート先が無いまま全員が締め出される）
2. `minimum_required_version` に、利用を許す最も古いバージョン（例: `1.4.0`）を入れて公開する。比較は桁ごとの数値で行う（`1.10.0`は`1.9.0`より新しい）
3. 必要なら `force_update_message` に本文を入れる。空ならアプリ内の文言（「引き続きhomeauをご利用いただくには、App Storeからアップデートをお願いします。」）が出る
4. 起動中の端末にはリアルタイム更新で届く。バックグラウンドにある端末は、次に復帰したときに届く

初期値は空文字（ブロックしない）で作成しておく。誤って引き上げた場合は、値を戻して公開すれば起動中の端末でも案内画面が解除される。

stgでの動作確認は、`minimum_required_version`を`99.0.0`のように現在より大きくして公開し、案内画面に切り替わること、空に戻すと解除されることを確かめる。

### 広告を緊急停止したいとき

`ads_enabled` を `false` にして公開する。起動中のアプリの広告は消えない。各端末でfetchがサーバーに問い合わせた後の起動から表示されなくなるため、Releaseでは全ユーザーに行き渡るまで最大12時間程度かかる。
