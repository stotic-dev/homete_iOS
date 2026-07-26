## タイトル: 課金基盤の実装に RevenueCat を採用する

* **ステータス（承認済）**
* 意思決定者: @stotic-dev
* 日付: 2026-05-23
* 技術的背景や関連チケット No: [Issue #178](https://github.com/stotic-dev/homete_iOS/issues/178)

## 文脈、背景や問題点の説明

homete にプレミアムプランを導入するため、iOS の In-App Purchase（IAP）を扱う仕組みを構築する必要がある。提供予定のプランは以下の3種類:

- `MonthlyPremium`: 月額サブスクリプション
- `YearlyPremium`: 年額サブスクリプション
- `OneTimeYearly`: 1年分の買い切り型課金（消費型ではない）

StoreKit を直接扱う場合、購入処理・レシート検証・サブスクリプション期限管理・復元購入・複数デバイス同期・サーバーサイド検証など、自前で構築すべき要素が多い。特に買い切り型 + サブスクリプションが混在するため、状態判定ロジックの実装と保守コストが高い。

これらを安全かつ短期間で実現する手段として、サードパーティの課金プラットフォームの採用を検討する。

## 決定事項

* RevenueCat iOS SDK（`Purchases` SDK）を Swift Package Manager 経由で導入する。
* SDK 統合先は既存の `HometeInfrastructure` モジュールとし、`HometeDomain` 側に課金関連のプロトコル（`BillingClient`）と値オブジェクト（`PlanContext` 等）を定義する。
* RevenueCat の AppUserID は Firebase Auth の uid と紐付け、ユーザー識別を Firebase Auth に一元化する。
* API キーは1つ（共通）を使用し、Sandbox / Production の区別は StoreKit 側に任せる（RevenueCat 標準動作）。

## 考慮した選択肢

* **選択肢1**: RevenueCat を採用
* **選択肢2**: StoreKit 2 を直接利用し、レシート検証は Firebase Functions 上に自前で実装
* **選択肢3**: 他の課金 SaaS（Adapty 等）を採用

## 決定結果

### 決定にあたり考慮したメリット

* サブスクリプション期限・購入履歴・復元購入・複数デバイス同期を RevenueCat 側で集約管理できる
* ダッシュボードからのプラン管理（Offerings）が可能で、価格変更や A/B テストへの追従が容易
* `CustomerInfo.entitlements` 経由で「プレミアム加入中か」をシンプルに判定でき、買い切り型と subscription を同じ Entitlement に束ねられる
* 公式 Swift SDK が成熟しており、Swift 6 / Sendable 対応も進んでいる
* 個人開発規模では無料枠（月収 \$2.5K まで）で運用可能

### 決定にあたり考慮したデメリット

* 外部 SaaS への依存が増える（障害時の影響、長期サポートの不確実性）
* 売上規模が拡大すると課金額が増える（収益の 1% 程度のレベニューシェア）
* RevenueCat 独自の概念（Offerings / Entitlements / Packages）の学習コスト

これらは個人開発フェーズで本当に必要になった段階で StoreKit 直接利用に切り替える余地もあり、今回はベンダーロックインを許容する。

## 参考

* RevenueCat 公式ドキュメント: https://www.revenuecat.com/docs/
* Issue #178: 課金実装の基盤構築
* 戦略ドキュメント: [billing-foundation.md](../strategy/billing-foundation.md)
