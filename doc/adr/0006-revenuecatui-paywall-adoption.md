## タイトル: Paywall（購入画面）UIの実装にRevenueCatUIを採用する

* **承認済**
* stotic-dev
* 日付: 2026-08-08
* 技術的背景: [ADR-0004](0004-revenuecat-sdk-adoption.md)で採用したRevenueCat SDKを使い、実際に購入手続きを行うPaywall UIを実装する（Issue #194）

## 文脈、背景や問題点の説明

ADR-0004でRevenueCat SDKをエンタイトルメント管理基盤として採用したが、ユーザーが実際に購入操作を行うPaywall（購入画面）は未実装だった。この画面をアプリ側で自前実装するか、RevenueCatが提供するPaywall UIコンポーネント（RevenueCatUI）を利用するかを検討する必要がある。

**Paywall UIを自前実装するか、RevenueCatUIを導入するか？**

## 決定事項

* RevenueCat公式が提供するUIコンポーネントパッケージ `RevenueCatUI`（`purchases-ios-spm`に含まれる同一リポジトリのproduct）を採用する
* サードパーティ依存を`HometeInfrastructure`に閉じ込める既存ルール（ADR-0004）を踏襲し、`RevenueCatUI`への直接依存は`HometeInfrastructure/Purchase/PaywallScreen.swift`に閉じ込める
* Paywallの訴求文言・レイアウト・価格表示はRevenueCatダッシュボード側の「Paywalls」設定に委ね、アプリ側はダッシュボードで作成したPaywallを表示するだけの薄いラッパー（`PaywallScreen`）を持つ
* `RevenueCatUI`はiOS専用パッケージのため、`Package.swift`で`RevenueCat`本体と同様に`condition: .when(platforms: [.iOS])`を付与し、`PaywallScreen`自体は`#if canImport(RevenueCatUI)`でmacOSホストビルド（`swift test --package-path LocalPackage`等）でも型としては解決できる形にする（`AdComponentResolver`/`BannerViewContainer`と同様のパターン）

## 考慮した選択肢

* **Paywall UIを自前実装**: デザインの自由度は最も高いが、価格表示のローカライズ、購入処理、リストア処理、エラーハンドリングをすべて自前で実装・保守する必要があり、開発コストが大きい
* **RevenueCatUIを採用（採用）**: RevenueCatダッシュボードでノーコードにPaywallをデザインでき、価格表示・購入・リストア・エラーハンドリングをSDK側が提供する。実装コストを大幅に抑えられる

## 決定結果

### 決定にあたり考慮したメリット

* Paywallの文言・レイアウト変更がアプリのリリースを介さずダッシュボード側で完結する（A/Bテストとも連携可能）
* 購入処理・リストア処理・エラー表示等のプラットフォーム標準的な挙動をSDKに委ねられ、実装コストと不具合リスクを抑えられる
* `HometeInfrastructure`に依存を閉じ込める既存パターンをそのまま踏襲できるため、アーキテクチャ上の追加コストがない

### 決定にあたり考慮したデメリット

* Paywallの実体（訴求文言・価格・レイアウト）がコード側だけでは完結せず、RevenueCatダッシュボード側の設定に依存する。ダッシュボード側の設定ミスがそのままアプリの表示に反映されるため、リリースフローにダッシュボード確認が必要になる
* `Purchases.configure`が未実行（APIキー未設定等）の状態で`PaywallView`を描画すると、RevenueCatUI内部で`fatalError`するデバッグ用エラー画面（release版）に到達する経路がある。そのため`PaywallScreen`側で`Purchases.isConfigured`を確認し、未configureの場合はエラー表示にフォールバックするガードを設けている
* 購入済みユーザーがPaywallを再度開いた場合、`PaywallView`は購読管理UIを兼ねない（購入ボタンは無反応になる）ため、購入済み状態のタップ操作はPaywallではなく`Purchases.shared.showManageSubscriptions()`によるOS標準のサブスクリプション管理画面へ誘導する設計とした

## 参考

* [RevenueCatUI Documentation](https://www.revenuecat.com/docs/tools/paywalls)
* [ADR-0004: 課金（サブスクリプション）機能の実装にRevenueCat SDKを採用する](0004-revenuecat-sdk-adoption.md)
