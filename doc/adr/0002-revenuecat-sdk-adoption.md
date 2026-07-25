## タイトル: 課金（サブスクリプション）機能の実装にRevenueCat SDKを採用する

* **承認済**
* stotic-dev
* 日付: 2026-07-25
* 技術的背景: プレミアム機能提供のための課金基盤導入

## 文脈、背景や問題点の説明

homete にサブスクリプション課金機能を導入するにあたり、App Store の StoreKit を直接扱うか、課金基盤を提供するサードパーティ SDK を利用するかを検討する必要がある。レシート検証、サーバーサイドでのエンタイトルメント管理、Web ダッシュボードでの契約状況確認などを自前で実装するとコストが大きい。

**StoreKit を直接実装するか、課金管理 SaaS を導入するか？**

## 決定事項

* 課金管理 SaaS として [RevenueCat](https://www.revenuecat.com/) を採用する
* SPM パッケージは `purchases-ios-spm`（RevenueCat公式が推奨する軽量版）を使用する
* サードパーティ依存は `HometeInfrastructure` のみが持つという既存の[マルチモジュール構成のルール](../multimodules_structure.md)に従い、RevenueCat SDK への直接依存は `HometeInfrastructure` に閉じ込める
* `HometeDomain` には RevenueCat に依存しない `PurchaseClient`（Client プロトコル）と `SubscriptionStore` を定義し、既存の `AccountAuthClient` / `AccountAuthStore` と同様の Client + Store パターンでエンタイトルメント状態を扱う
* ユーザーのログイン/ログアウトと連動して `Purchases.shared.logIn` / `logOut` を呼び出し、匿名ユーザーIDとアカウントIDを紐付ける

## 考慮した選択肢

* **StoreKit 2 を直接実装**: 外部 SaaS への依存がなくなるが、レシート検証・サブスク状態管理・複数プラットフォームでのエンタイトルメント統合などを自前で構築・運用する必要があり、開発コストと保守コストが大きい
* **RevenueCat（`purchases-ios` フル版）**: Objective-C 互換や CocoaPods 等もサポートするフル機能版。本プロジェクトは SPM 専用構成のため、フル版のメリットを活かせない
* **RevenueCat（`purchases-ios-spm`、採用）**: SPM に最適化された軽量パッケージで、RevenueCat公式が現在のQuickstartで推奨している

## 決定結果

### 決定にあたり考慮したメリット

* レシート検証・サブスクリプション状態管理・Web ダッシュボードでの分析が RevenueCat 側で提供され、開発コストを抑えられる
* `PurchaseClient` を Client プロトコルとして抽象化することで、既存の DI パターンを崩さずに導入でき、テスト時は `previewValue` でモック可能
* 将来的に Android 版を開発する場合も RevenueCat は Android SDK を提供しており、バックエンドのエンタイトルメント管理を共通化できる

### 決定にあたり考慮したデメリット

* RevenueCat への外部依存が増え、料金プラン（MTR無料枠超過時の課金等）や障害時のリスクを負う
* エンタイトルメント/プロダクト/オファリングの実体は RevenueCat ダッシュボード側の設定に依存するため、コード側だけでは完結しない（本ADR時点ではダッシュボード未設定のため、Entitlement識別子は仮で `"premium"` を使用している）

## 参考

* [RevenueCat Quickstart](https://www.revenuecat.com/docs/getting-started/quickstart)
* [purchases-ios-spm](https://github.com/RevenueCat/purchases-ios-spm)
