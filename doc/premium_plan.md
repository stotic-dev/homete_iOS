# hometeの提供価値とプレミアムプランの訴求整理

> 目的: アプリの提供価値とプレミアムプランの訴求内容を整理し、今後の機能検討・訴求文言整備の土台とする。
> 参照Issue: [#158](https://github.com/stotic-dev/homete_iOS/issues/158) 課金実装で開放する機能の検討 / [#178](https://github.com/stotic-dev/homete_iOS/issues/178) 課金実装の基盤構築 / [#194](https://github.com/stotic-dev/homete_iOS/issues/194) Paywall基盤実装と設定画面導線 / [#197](https://github.com/stotic-dev/homete_iOS/issues/197) プレミアム会員向け家事データ保存期間の無制限化
> 関連ADR: [ADR-0002](adr/0002-billing-revenuecat.md) 課金基盤の実装にRevenueCatを採用する
> 関連戦略ドキュメント: [billing-foundation.md](strategy/billing-foundation.md) / [premium-housework-storage-period.md](strategy/premium-housework-storage-period.md) / [admob-personalize.md](strategy/admob-personalize.md)

## 1. hometeが提供する価値（無料版）

hometeは同居人（ルームメイト/家族）間で家事を管理するためのiOSアプリ。**無料版だけで全ての家事管理機能を利用できる**ことを設計方針としている（`PremiumIntroductionView.swift`の文言「hometeは無料のままでもすべての家事管理機能をお使いいただけます」に明記）。

コア体験は以下の4つ:

| 価値 | 内容 |
|---|---|
| 家事の共有管理 | 共有の家事リスト（`HouseworkBoardList`/`HouseworkItem`）を作成し、誰が何をやるかを明確化する |
| 完了通知 | 誰かが家事を完了としてマークすると、他の同居人にプッシュ通知が届く |
| 貢献度の可視化 | ContributionFeatureで「誰がどれだけ家事をしたか」をデータで示し、家事分担の不公平感を解消する。hometeの中核的な差別化要素 |
| テンプレート機能 | HouseworkTemplateFeatureで繰り返し発生する家事の登録の手間を削減する |

## 2. プレミアムプランの訴求内容

### 2.1 特典（現状確定分）

Issue #158の当初検討では「広告非表示」「分析期間の無制限化」など複数の特典候補が挙がっていたが、Issue #194で**以下の2点に絞る改訂**が行われている。

| 特典 | 内容 | 実装状況 |
|---|---|---|
| 広告非表示 | ダッシュボードのバナー広告（AdMob）が消える | 実装済み（#194） |
| 家事データ保存期間の無制限化 | 無料は閲覧「直近3ヶ月」・保持「登録日+1年」。プレミアムは閲覧・保持ともに無制限 | 実装済み（#197、貢献度の分析グラフ・家事ボードの過去閲覧に反映） |

このほか、オンボーディング（`PremiumIntroductionView`）では「今後追加される機能もすべて追加料金なしで使える」という将来価値も訴求しているが、**プレミアム限定機能を都度解放する制度・ドメインロジックは現状存在しない**（文言のみが先行している状態）。

### 2.2 課金プラン体系

RevenueCat経由のIn-App Purchaseとして、月額/年額の自動更新サブスクリプションを提供する。

- 月額サブスクリプション
- 年額サブスクリプション

[ADR-0002](adr/0002-billing-revenuecat.md)では上記に加えて`OneTimeYearly`（1年分の買い切り型課金）も設計されていたが、**2026-08-08のコミット（`2066bd1`）で買い切りプランの提供終了に伴い実装から削除済み**。現行の`SubscriptionPlan`（`LocalPackage/Sources/HometeDomain/Subscription/SubscriptionPlan.swift`）は`.free`と`.subscription`（月額/年額）のみを表現し、買い切り（`lifetime`）の分岐は存在しない。ADR-0002は当時の意思決定記録として残すが、現行プランの根拠としては参照しないこと。

### 2.3 訴求が露出する導線

1. **オンボーディング** `PremiumIntroductionView` — 「広告が表示されません」「今後追加される機能もすべて使えます」の2枚看板を提示し、「プランを見る」からPaywallへ遷移
2. **広告バナー直下** `RemoveAdsPromotionLink` — 「広告を非表示にする」のテキストリンク
3. **保存期間の上限到達時** — 家事ボード過去端・貢献度分析画面で「プレミアムプランに登録すると全期間閲覧できます」のブロック表示＋CTA
4. **設定画面** `SubscriptionManagementView` — 現在のプラン確認・変更・購入復元・解約導線
5. **購入画面本体** `PaywallScreen` — RevenueCatUIの`PaywallView`標準コンポーネントに委譲しており、価格やプラン説明はアプリ側にハードコードされず**RevenueCatダッシュボード側のPaywall設定に依存**する

## 3. 論点・今後の検討事項

- **「今後追加される機能も使える」の実体制度がない**: オンボーディングの謳い文句にとどまり、新機能をプレミアム限定として都度解放する仕組みは未設計。今後この文言との整合を意識する必要がある
- **3つ目の価値の柱が未検討**: 現状「広告非表示」「保存期間無制限」の2点で構成されており、Issue #158で言及されていた他の特典候補（分析機能の追加拡張など）は具体化していない。プレミアム価値を拡張する場合の検討余地として残っている
- **Paywall文言はRevenueCatダッシュボード管理**: アプリコード側に価格・訴求コピーの実体がないため、訴求内容を変更する場合はRevenueCat側の設定変更が必要になる（アプリ側の補足UI＝上記2.3の1〜3は除く）
