## タイトル: App Intentsは書き込みをStoreと共有するUseCaseで実行し、完了の家事は名前で表す

* **ステータス: 提案済**
* 意思決定者: stotic-dev
* 日付: 2026-10-12
* 関連: [Issue #434](https://github.com/stotic-dev/homete_iOS/issues/434)、[実装方針](../strategy/app-intents-donation.md)

## 文脈、背景や問題点の説明

アプリを開かなくても、Siri・Spotlight・ショートカットから家事の完了・ありがとう・がんばりの確認をできるようにしたい。
アプリの中での操作をドネーションして、OSに提案させたい。
家事の書き込みは今、スナップショットリスナーを張る`HouseworkListStore`に入っている。家事は日ごとに別のIDで作られる。
Intentから何を呼ぶか、ドネーションの引数で家事をどう表すか。

## 決定事項

* App Intents（iOS 17で使えるAPI）を採用し、Extensionは作らずアプリのプロセスで実行する
* 家事の完了・ありがとうの書き込み・Analytics・通知を`HouseworkCommandUseCase`に切り出し、`HouseworkListStore`とIntentの両方から呼ぶ
  * 「最新の家事を探す」のは呼び出し側。Storeはリスナーの家事、Intentはサーバーから1回取り直した家事を渡す
* Intentは`HometeAppIntents`ターゲットに置き、Firebaseの実装は`AppDependencyManager`経由で受け取る（`HometeInfrastructure`に依存させない）
* 完了のIntentの家事は**名前**をIDにしたEntityで表す。実行時に今日の同じ名前の未完了の家事を探して完了にする
* ありがとうのドネーションには家事を引数に入れず、実行時に候補から解決する
* ドネーションは`HometeDomain`の`IntentDonationClient`経由で行い、`HometeDomain`をApp Intentsに依存させない

## 考慮した選択肢

* 書き込み
  * A. Intentから`HouseworkListStore`を作って呼ぶ: リスナーの初回スナップショットを待つ必要があり、Intentの短い実行時間とリスナーの寿命が合わない
  * B. Intent用に書き込みを別実装する: 通知の条件やAnalyticsが食い違う
  * C. 書き込みをUseCaseに切り出して共有する（採用）
* 完了の家事の表し方
  * A. 家事のIDをEntityのIDにする: ドネーションした翌日の提案が、もう終わった昨日の家事を指す
  * B. テンプレートの家事IDにする: テンプレートから作っていない家事を扱えない
  * C. 家事の名前にする（採用）: 毎日の家事は名前が変わらないので、翌日も同じ提案が使える
* 置き場所
  * A. メインターゲットに置く: パッケージのテストで扱えない
  * B. LocalPackageの新しいターゲットに置く（採用。メタデータが抽出できない場合はAに戻す）

## 決定結果

### 決定にあたり考慮したメリット

* アプリとIntentで、完了・ありがとうの通知の条件とAnalyticsがそろう
* ドネーションした提案が日をまたいで使える
* UseCase・候補の判定をユニットテストできる

### 決定にあたり考慮したデメリット

* 同じ日に同じ名前の家事が複数あると、作成日時の古い方を完了にする（ユーザーは選べない）
* 家事の名前を変えると、それまでの提案は使えなくなる
* `HouseworkListStore`のリファクタリングが先に必要になる

## 参考

* [App Intents | Apple Developer Documentation](https://developer.apple.com/documentation/appintents)
