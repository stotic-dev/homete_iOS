# Remote Config

> fetch・activateのタイミングと、キーごとの反映方針を決めた経緯は [ADR-0033](adr/0033-remote-config-fetch-and-per-key-apply-timing.md) を参照。
> 強制アップデートの判定・表示方式とリアルタイム更新を採用した経緯は [ADR-0035](adr/0035-force-update-with-realtime-remote-config.md) を参照。
> メンテナンスモードの止め方・強制アップデートとの優先順位は [ADR-0055](adr/0055-maintenance-mode-with-remote-config.md) を参照。

## パラメータ一覧

| キー | 型 | アプリ内デフォルト値 | 内容 | 反映タイミング |
|---|---|---|---|---|
| `ads_enabled` | Boolean | `false` | 広告表示を有効にするかどうか。プレミアム加入者には値によらず広告を出さない | 起動時のfetch完了時に確定し、起動中は変えない |
| `minimum_required_version` | String | `""`（ブロックしない） | これより古いバージョンは強制アップデート画面で利用を止める（例: `1.4.0`）。空・不正な値ならブロックしない | 値を反映するたびに判定し直す（起動中も即時） |
| `maintenance_enabled` | Boolean | `false`（ブロックしない） | `true`ならアプリ全体をメンテナンス画面で止める。App Intentも実行させず、Notification Service Extensionはふりかえり通知を予約しない。強制アップデートより優先する | 値を反映するたびに判定し直す（起動中も即時） |

アプリ内デフォルト値は `RemoteConfigBoolKey.defaultValue` / `RemoteConfigStringKey.defaultValue`（`LocalPackage/Sources/HometeDomain/RemoteConfig/`）で定義している。キーを足すときは、コンソールへの登録とこの表の更新も併せて行う。

## アプリ側の挙動

| タイミング | 処理 |
|---|---|
| 起動時 | `fetchAndActivate()`（起動処理とは並行。完了を待たない） |
| バックグラウンドからの復帰時 | `fetchAndActivate()` |
| コンソールで変更を公開したとき（フォアグラウンド中のみ） | リアルタイム更新を受け取ってactivateする（`minimumFetchInterval`に関係なく届く） |

起動時・復帰時の取得は`RemoteConfigSyncUseCase`が1回だけ行い、値を使う領域のStore（`AdvertisementStore` / `ForceUpdateStore` / `MaintenanceStore`）へ反映させる。リアルタイム更新も`RemoteConfigSyncUseCase`が1つのリスナーで購読し、起動中も反映するキー（強制アップデート・メンテナンス）のStoreへ判定し直させる。

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
   - `maintenance_enabled`: データ型 Boolean、デフォルト値 `false`
3. **変更を公開** を押す。公開するまでアプリには配信されない
4. 動作確認
   - stg: TestFlightまたはXcodeから実行したビルドを再起動し、非プレミアムのアカウントで広告の表示・非表示が切り替わることを確認する
   - prod: App Store版は最大12時間程度かかるため、アプリの再インストールで即時に確認する（再インストールでfetchの最小間隔がリセットされる）

### 強制アップデートをかけたいとき

1. 対象のバージョンより新しいバージョンがApp Storeで配信済みであることを確認する（未配信のまま公開すると、アップデート先が無いまま全員が締め出される）
2. `minimum_required_version` に、利用を許す最も古いバージョン（例: `1.4.0`）を入れて公開する。比較は桁ごとの数値で行う（`1.10.0`は`1.9.0`より新しい）
3. 起動中の端末にはリアルタイム更新で届く。バックグラウンドにある端末は、次に復帰したときに届く

初期値は空文字（ブロックしない）で作成しておく。誤って引き上げた場合は、値を戻して公開すれば起動中の端末でも案内画面が解除される。

stgでの動作確認は、`minimum_required_version`を`99.0.0`のように現在より大きくして公開し、案内画面に切り替わること、空に戻すと解除されることを確かめる。

### メンテナンスで利用を止めたいとき

障害時などに、アプリ全体の利用を一時的に止める。アップデートで解消しない状況では、強制アップデートではなくこちらを使う。

1. `maintenance_enabled` を `true` にして公開する
   - 起動中の端末にはリアルタイム更新で届き、どの画面にいても（表示中のシートも閉じて）メンテナンス画面に切り替わる
   - バックグラウンドにある端末は、次に復帰したときに届く
   - App Intent（Siri・ショートカット）は「メンテナンス中のため、いまは使えません」と返して実行しない
   - まだ使われていない通知・招待リンク・App Intentの開く画面と、メンテナンス中に開かれたものは破棄する（終わった後に急に開かない）
2. 終えるときは `maintenance_enabled` を `false` に戻して公開する。起動中の端末は、そのまま元の画面に戻る

止められない端末があることに注意する（[ADR-0055](adr/0055-maintenance-mode-with-remote-config.md)）。

- フェイルオープンのため、Remote Configが届かない端末（オフライン、Realtime APIが無効で復帰時のfetch頼み、Releaseで最大12時間）とこの機能より前のバージョンは止まらない
- 初回起動などで前回の値を反映できていない端末は、起動時のfetchが終わるまで（通常は数秒）通常の画面が出る
- Firestoreルール・Functionsでは書き込みを拒否しない。データ移行のように書き込みを確実に止めたい用途には足りない
- 止めるのはユーザーが操作できる入口だけで、起動時の同期（FCMトークン・プレミアム状態の保存）はメンテナンス中も動く
- メンテナンス前に予約済みのふりかえり通知は取り消さない
- Notification Service Extensionは、アプリが最後に反映した判定を使う。メンテナンス中にアプリを閉じた端末は、終わった後にアプリを開くまでふりかえり通知を予約しない

stgでの動作確認は、`maintenance_enabled`を`true`にして公開し、起動中のアプリがメンテナンス画面に切り替わること、Siri・ショートカットから家事の完了を実行すると止まること、`false`に戻すと元の画面に戻ることを確かめる。

### 広告を緊急停止したいとき

`ads_enabled` を `false` にして公開する。起動中のアプリの広告は消えない。各端末でfetchがサーバーに問い合わせた後の起動から表示されなくなるため、Releaseでは全ユーザーに行き渡るまで最大12時間程度かかる。
