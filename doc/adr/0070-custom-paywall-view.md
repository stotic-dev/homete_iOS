## タイトル: Paywall（購入画面）の見た目を自前のSwiftUI Viewにし、訴求内容をコードで持つ

* **承認済**
* stotic-dev
* 日付: 2026-11-07
* 技術的背景: [ADR-0006](0006-revenuecatui-paywall-adoption.md)（RevenueCatUIの採用）を置き換える。Issue [#404](https://github.com/stotic-dev/homete_iOS/issues/404)、実装方針は [custom-paywall.md](../strategy/custom-paywall.md)

## 文脈、背景や問題点の説明

ADR-0006ではPaywallをRevenueCatUIの`PaywallView`で表示し、訴求文言・レイアウト・価格表示をRevenueCatダッシュボードの設定に任せた。運用してみると、hometeの使い方とこの構成が合っていなかった。

* プロダクト・価格はほとんど変えないので、ダッシュボードで変えられる利点が効いていない
* 訴求内容は新機能の追加にあわせてよく変わる。ダッシュボードの文言は全バージョンで共通なので、新機能の訴求を入れると旧バージョンのユーザーにも「まだ使えない機能」を訴求してしまう。機能のリリースと訴求を同期させられない
* Paywallの実体がコードに無く、PreviewとVRTの対象にできない。ダッシュボードの設定ミスがそのままアプリに出る
* SDKの都合の回避策（`Purchases.isConfigured`のガード、購入済みの人が開くと購入ボタンが反応しない問題）が要る

**訴求内容を機能のリリースと同期させ、ほかの画面と同じ方法で品質を守るには、Paywallをどう持てばよいか？**

## 決定事項

* Paywallの**見た目だけ**を自前のSwiftUI Viewにし、新しい`PaywallFeature`モジュールに置く。`RevenueCatUI`への依存はなくす
* 購入・リストア・エンタイトルメント管理は引き続きRevenueCat SDK（`RevenueCat`）に任せる。`PurchaseClient`にプラン一覧の取得（`fetchOffering`）と購入（`purchase`）を足し、SDKの型はドメインモデル（`PurchaseOffering`・`PurchaseResult`）に変換して返す
* 訴求する特典は`PaywallBenefit`のケースとしてコードに持つ。機能の追加・訴求の追加・VRTの更新が同じPRにまとまる
* 価格・課金期間・導入オファーはRevenueCatのOfferingから取得して出す。App Store審査ガイドライン3.1.2の必須表示（自動更新・解約方法・利用規約とプライバシーポリシー）もアプリ側で出す
* 契約中の人が開いたときは、プランの一覧ではなく既存の契約プラン画面を出す。契約プラン画面の「プランを変更」からはプランの一覧を出し、契約中のプランは選べなくする
* 購入の失敗とプラン一覧の取得の失敗は、新しく足した`ErrorReportClient`でCrashlyticsの非致命イベントとして記録する

## 考慮した選択肢

* **RevenueCatUIを使い続ける**: 文言をリリースなしで変えられるが、訴求内容を機能のリリースと同期できない。プロダクト・価格を変える頻度が低いので、ダッシュボードで管理する利点も小さい
* **StoreKit 2を直接使い、決済まで自前で作る**: レシート検証・トランザクション監視・エンタイトルメント管理を自前で持つことになり、得られるものに対してコストが大きすぎる
* **StoreKitの`SubscriptionStoreView`を使う**: ガイドラインの表示要件をある程度満たしてくれるが、見た目の自由度が低い。RevenueCat側へのエンタイトルメントの反映も追加で確かめる必要がある
* **見た目だけ自前のViewにし、決済はRevenueCat SDKに任せる（採用）**

## 決定結果

### 決定にあたり考慮したメリット

* 訴求内容が機能と同じバージョンに入るので、旧バージョンに使えない機能を訴求したり、新バージョンで訴求が漏れたりしない
* PaywallがPreviewとVRTの対象になり、デザインシステム（HometeUI）にそろえられる
* `RevenueCatUI`の回避策（未初期化時の`fatalError`の経路、購入済みの人の購入ボタン）が要らなくなる

### 決定にあたり考慮したデメリット

* 訴求文言を変えるにはアプリのリリースが要る。ダッシュボードでのA/Bテストもできなくなる
* 導入オファーの表記・ガイドライン3.1.2の必須表示を自分たちで保守する必要がある
* 旧バージョンはダッシュボードのPaywallを表示し続けるため、置き換え後のバージョンが行き渡るまでダッシュボードのPaywalls設定を残しておく必要がある

## 参考

* [ADR-0004: 課金（サブスクリプション）機能の実装にRevenueCat SDKを採用する](0004-revenuecat-sdk-adoption.md)
* [ADR-0006: Paywall（購入画面）UIの実装にRevenueCatUIを採用する](0006-revenuecatui-paywall-adoption.md)
* [App Store Review Guidelines 3.1.2](https://developer.apple.com/app-store/review/guidelines/#subscriptions)
