# 自前のPaywall 実装方針

> 関連Issue: [#404 Enhancement: ペイウォールをRevenueCatUIから自前のViewに置き換える](https://github.com/stotic-dev/homete_iOS/issues/404)
> ブランチ: `feat/404-custom-paywall`

## ステータス

- [x] 要件確定
- [x] 設計確定
- [ ] 実装完了
- [ ] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

Paywall（購入画面）の見た目を、RevenueCatUIの`PaywallView`から自前のSwiftUI Viewに置き換える。訴求内容をコードに書くことで、機能の追加・訴求の追加・VRTの更新を同じPRにまとめ、機能のリリースと訴求を同期できるようにする。購入・リストア・エンタイトルメント管理は引き続きRevenueCat SDK（`RevenueCat`）に任せ、`RevenueCatUI`への依存はなくす。

## 要件

### 機能要件

**プラン一覧（未購入の人）**

- 訴求する特典の一覧、プラン一覧（月額・年額）、購入ボタン、購入を復元するボタン、閉じるボタンを出す
- 最初は年額を選んだ状態にする。年額には「月あたり¥◯◯」を出す
- 導入オファー（無料トライアルなど）は、利用資格がある人にだけ表記を出す
- App Store審査ガイドライン3.1.2の必須表示を入れる: 価格、課金期間、自動更新であること、解約方法、利用規約とプライバシーポリシーへのリンク
- プランの取得中は読み込み中の表示、取得に失敗したら「もう一度試す」「閉じる」を出す

**購入**

- 購入ボタンを押すと、選んだプランを購入する。購入中は二重に押せないようにする
- 購入が完了したら、Paywallの中でお礼と特典が使えるようになった旨を出し、「閉じる」で元の画面に戻る
- ユーザーがキャンセルしたら何も出さず、プラン一覧に戻る
- 承認待ち（ペアレンタルコントロールの「承認と購入のリクエスト」など）になったら、承認されると使えるようになる旨を伝える
- 失敗したらアラートで伝える。**失敗はCrashlyticsの非致命イベントとして記録する**（キャンセル・承認待ちは記録しない）
- プラン一覧の取得の失敗も、Crashlyticsの非致命イベントとして記録する（「商品が取れない」問題を追うため）

**購入を復元**

- 既存の`SubscriptionStore.restorePurchases(for:)`を使う。復元できたら購入完了と同じ表示にする。見つからない・失敗したときは`SubscriptionManagementView`と同じ文言でアラートを出す

**購入済みの人が開いたとき**

- `AppRoute.paywall`を開いたときにプレミアムなら、プラン一覧ではなく既存の契約プラン画面（`SubscriptionManagementView`）を出す
- 契約プラン画面の「プランを変更」からは、判定を飛ばしてプラン一覧を直接出す（開き直しのループを防ぐ）。今契約中のプランには「利用中」と出して選べないようにする

### 非機能要件 / 制約

- 新しく`PaywallFeature`モジュールを作り、Paywallの画面を置く（呼び出し元が多くのFeatureにまたがるため）。VRTの対象にする
- 匿名ユーザーへのApple連携の要求と、購入者をアカウントに結び付ける準備は、今の`PaywallGate`（`AppRoot`）にそのまま任せる
- 購入成功・失敗のAnalyticsイベントは足さない。`paywall`イベント（`shown` / `closed`）は、今と同じくプラン一覧を出したとき・閉じたときに送る
- RevenueCatダッシュボードのPaywalls設定は、置き換え後のバージョンが行き渡るまで残す（旧バージョンはまだそれを表示するため）
- 文言は`ux-writing.md`に沿って書き、英訳も同じ変更で入れる（`make check-translations`）

## 設計方針

### 1. 画面の出し分け（`PaywallGate`）

`InfraPackage/Sources/AppRoot/ResolverImpl/AccountLinkRoutes.swift`の`PaywallGate`は、今の準備の流れ（匿名ならApple連携 → 購入者の準備 → 表示）を残し、`.ready`のときに出すものだけ変える。

```swift
case .ready:
    if subscriptionStore.isPremium && !isPlanChange {
        // 契約プラン画面。NavigationStackと閉じるボタンを付けた公開用のScreenをSettingFeatureに用意する
        SubscriptionManagementScreen(onClose: { dismiss() })
    } else {
        PaywallScreen(onClose: { dismiss() })   // PaywallFeature
            .onAppear { appearedPaywall() }
            .onDisappear { disappearedPaywall() }
            .trackScreenView(.paywall)
    }
```

- 判定を飛ばすかどうかは`AppRoute`に明示的に持たせる。`step`の値で暗黙に分けない

  ```swift
  case paywall(step: PaywallAnalyticsStep?, isPlanChange: Bool = false)
  ```

  `SubscriptionManagementView`の「プランを変更」は、契約中なら`.paywall(step: .subscriptionManagement, isPlanChange: true)`を開く
- 契約プラン画面を出したときは`paywall`イベントを送らない（`screen_view`は`subscription_management`が送られる）
- `PaywallPreparationErrorView`はそのまま使う

### 2. Domain / Client

`LocalPackage/Sources/HometeDomain/Dependencies/PurchaseClient.swift`に2つ足す。

```swift
/// 表示するプランの一覧。導入オファーは利用資格がある場合だけ入れる
public let fetchOffering: @Sendable () async throws -> PurchaseOffering
/// プランを購入する
public let purchase: @Sendable (_ packageId: String) async throws -> PurchaseResult
```

`LocalPackage/Sources/HometeDomain/Subscription/`にドメインモデルを足す。

```swift
public struct PurchaseOffering: Equatable, Sendable {
    public let packages: [PurchasePackage]
}

public struct PurchasePackage: Equatable, Sendable, Identifiable {
    public let id: String                  // RevenueCatのPackageのidentifier
    public let productIdentifier: String   // 契約中のプランとの突き合わせに使う
    public let period: SubscriptionPeriod
    public let localizedPrice: String      // 「¥3,000」
    public let localizedPricePerMonth: String?  // 年額のみ「¥250」
    public let introductoryOffer: IntroductoryOffer?  // 利用資格がない・オファーが無ければnil
}

public struct IntroductoryOffer: Equatable, Sendable {
    public let paymentMode: PaymentMode   // 無料トライアル / 割引価格など
    public let period: SubscriptionPeriodUnit  // 「1週間」などの期間（単位と数）
    public let localizedPrice: String
}

public enum PurchaseResult: Equatable, Sendable {
    case purchased(EntitlementInfo)
    case cancelled
    case pending
}
```

`liveValue`（`InfraPackage/Sources/AppRoot/Dependency/Impl/ImplPurchaseClient.swift`）:

- `fetchOffering`: `Purchases.shared.offerings().current`から変換する。`current`が無ければエラー。導入オファーの利用資格は`checkTrialOrIntroDiscountEligibility(product:)`で確かめる。月あたり価格は`StoreProduct.localizedPricePerMonth`
- `purchase`: `offerings().current`から`packageId`のPackageを引き、`Purchases.shared.purchase(package:)`する。`userCancelled`なら`.cancelled`、`ErrorCode.paymentPendingError`なら`.pending`
- 呼ぶ前に`Purchases.isConfigured`を確かめ、未設定ならエラーを投げる（`fatalError`の経路を通らないように）

`SubscriptionStore`に、`restorePurchases(for:)`と同じ形で購入を足す。購入結果をすぐ`entitlementInfo`に反映し、`isPremium`のユーザープロパティを更新する。

```swift
public func purchase(_ packageId: String, for accountId: String) async throws -> PurchaseResult
```

### 3. Crashlyticsの非致命イベント

非致命のエラーを記録するClientが今は無いので足す。ベンダー名は型に出さない（`AnalyticsClient`と同じ方針）。

```swift
// LocalPackage/Sources/HometeDomain/Dependencies/ErrorReportClient.swift
public struct ErrorReportClient: Sendable {
    /// 非致命のエラーとして記録する
    public let record: @Sendable (_ error: any Error, _ context: [String: String]) -> Void
}
```

- `liveValue`は`InfraPackage/Sources/AppRoot/Dependency/Impl/ImplErrorReportClient.swift`で`Crashlytics.crashlytics().record(error:userInfo:)`
- `AppDependencies`に足す
- Paywallでは購入の失敗とプラン一覧の取得の失敗を記録する。`context`には操作（`purchase` / `fetch_offering`）と、購入なら`packageId`を入れる

### 4. PaywallFeatureの画面

`ui-logic-view-separation.md`に沿って、ロジックを持つ`PaywallScreen`とUIのみの`PaywallView`に分ける。

| View | 役割 |
|---|---|
| `PaywallScreen`（public） | `PaywallStore`を持ち、プランの取得・購入・復元・アラート・閉じる操作を受け持つ |
| `PaywallView` | 状態を受け取って、読み込み中・プラン一覧・購入完了・取得失敗を描き分ける。`#Preview`はここに書く |
| `PaywallBenefitListContent` | 特典の一覧 |
| `PaywallPlanOptionContent` | プラン1つ分の選択肢（価格・期間・月あたり価格・導入オファー・利用中） |
| `PaywallLegalNoticeContent` | 自動更新・解約方法の説明と、利用規約・プライバシーポリシーへのリンク |
| `PaywallCompletedContent` | 購入完了のお礼 |

**訴求する特典**は`Model/PaywallBenefit.swift`にケースだけを持つenumとして置き、`CaseIterable`の順に並べる。文言とSF Symbolは`ui-attributes-in-view.md`に沿ってView側の`private extension`で決める。特典を足すときはケースと見せ方を1つずつ足すだけで済む。

```swift
enum PaywallBenefit: CaseIterable {
    case noAds              // 広告が表示されません
    case unlimitedHistory   // 家事の記録を、期間の制限なく振り返れます
    case houseworkImage     // 家事に写真を添えられます
}
```

訴求する内容は`doc/premium_plan.md`の「2.1 特典」と、`HouseworkImagePolicy`などのプラン判定で実際に解放されていることを確かめてから書く（`ux-writing.md`の原則4）。

**状態**は`Model/PaywallStore.swift`（`@MainActor @Observable`）に持つ。

```swift
enum PaywallPhase: Equatable {
    case loading
    case loaded(PurchaseOffering)
    case loadFailed
    case completed
}

// PaywallStoreが持つもの
var phase: PaywallPhase
var selectedPackageId: String?     // 取得したら年額を選ぶ。年額が無ければ先頭
var isPurchasing: Bool             // 購入・復元中。ボタンを止めてローディングを出す
var alert: PaywallAlert?           // 購入失敗 / 承認待ち / 復元の結果
```

- 契約中のプランは`SubscriptionStore.entitlementInfo.productIdentifier`と`PurchasePackage.productIdentifier`で突き合わせる。利用中のプランは選べず、初期選択からも外す
- 利用規約・プライバシーポリシーのURLは`HometeUI/ViewUtilities/Constants.swift`にあるものを使う
- 法務・課金の画面なので、ほめっとのセリフは出さない（`ux-writing.md`）
- スピナーが写るPreview（読み込み中・購入中）は`.prefireIgnored()`を付ける

### 5. RevenueCatUIの削除

- `InfraPackage/Sources/HometeInfrastructure/Purchase/PaywallScreen.swift`を消す
- `InfraPackage/Package.swift:50`の`RevenueCatUI`を外す。`purchases-ios-spm`は`RevenueCat`で使い続けるので`Package.resolved`は変わらない

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規モジュール | `LocalPackage/Sources/Features/PaywallFeature/` | Paywallの画面一式 |
| 新規View | `PaywallFeature/PaywallScreen.swift` / `PaywallView.swift` | ロジックを持つ画面 / UIのみの画面 |
| 新規View | `PaywallFeature/SubViews/*Content.swift` | 特典・プラン・法務表示・購入完了 |
| 新規Model | `PaywallFeature/Model/PaywallBenefit.swift` / `PaywallStore.swift` / `PaywallPhase.swift` | 特典の一覧 / 画面の状態 |
| 新規テスト | `LocalPackage/Tests/PaywallFeatureTests/PaywallStoreTest.swift` | 初期選択・購入の結果ごとの状態・エラーの記録 |
| 修正Package | `LocalPackage/Package.swift` | `PaywallFeature`と`PaywallFeatureTests`を足す |
| 修正Package | `InfraPackage/Package.swift` | `AppRoot`に`PaywallFeature`を足し、`RevenueCatUI`を外す |
| 修正Client | `HometeDomain/Dependencies/PurchaseClient.swift` | `fetchOffering`・`purchase` |
| 新規Client | `HometeDomain/Dependencies/ErrorReportClient.swift` | 非致命のエラーの記録 |
| 修正DI | `HometeDomain/Dependencies/AppDependencies.swift` | `errorReportClient`を足す |
| 新規ドメイン | `HometeDomain/Subscription/PurchaseOffering.swift` / `PurchaseResult.swift` | プラン一覧・購入の結果 |
| 修正Store | `HometeDomain/Subscription/SubscriptionStore.swift` | `purchase(_:for:)` |
| 修正テスト | `LocalPackage/Tests/HometeDomainTests/.../SubscriptionStoreTest.swift` | `purchase`の反映 |
| 修正Route | `HometeDomain/Navigation/AppRoute.swift` | `paywall`に`isPlanChange` |
| 修正View | `Features/SettingFeature/SubscriptionManagement/SubscriptionManagementView.swift` | 契約中なら`isPlanChange: true`で開く |
| 新規View | `Features/SettingFeature/SubscriptionManagement/SubscriptionManagementScreen.swift`（public） | Paywallから出す契約プラン画面（NavigationStackと閉じるボタン） |
| 修正Live | `InfraPackage/Sources/AppRoot/Dependency/Impl/ImplPurchaseClient.swift` | `fetchOffering`・`purchase`の実装 |
| 新規Live | `InfraPackage/Sources/AppRoot/Dependency/Impl/ImplErrorReportClient.swift` | Crashlyticsへの記録 |
| 修正Gate | `InfraPackage/Sources/AppRoot/ResolverImpl/AccountLinkRoutes.swift` / `RouteResolverInjection.swift` | 出し分け |
| 削除 | `InfraPackage/Sources/HometeInfrastructure/Purchase/PaywallScreen.swift` | RevenueCatUIのラッパー |
| 修正VRT | `.prefire.yml` / `hometeVRT.xcodeproj` | `PaywallFeature`を`testable_imports`とテストターゲットのリンクに足す |
| 修正文言 | `PaywallFeature/Resources/Localizable.xcstrings` ほか | 日本語と英訳 |

## タスク

### Phase 1: 設計確定

- [x] 購入済みの人が開いたら、既存の契約プラン画面を出す
- [x] 契約プラン画面の「プランを変更」からはプラン一覧を直接出し、契約中のプランは「利用中」で選べなくする
- [x] 新しく`PaywallFeature`モジュールを作る
- [x] 購入成功・失敗のAnalyticsイベントは足さない。購入の失敗とプラン一覧の取得の失敗はCrashlyticsの非致命イベントで記録する
- [x] 最初は年額を選び、月あたり価格を出す
- [x] 購入が完了したら、お礼を出してから閉じる

### Phase 2: 実装

コミットは対応ごとに分ける（`git-commit.md`）。

- [ ] `ErrorReportClient`と`liveValue`を足し、`AppDependencies`に登録する
- [ ] `PurchaseOffering`・`PurchaseResult`などのドメインモデルと、`PurchaseClient`の`fetchOffering`・`purchase`（`previewValue`・`liveValue`）を足す
- [ ] `SubscriptionStore.purchase(_:for:)`とテストを足す
- [ ] `PaywallFeature`モジュールと`PaywallFeatureTests`を`Package.swift`に足す
- [ ] `PaywallStore`とユニットテストを書く
- [ ] `PaywallView`とSubViews、Previewを作る（未購入・導入オファーあり・プラン変更で利用中あり・購入完了・取得失敗。読み込み中・購入中は`.prefireIgnored()`）
- [ ] `PaywallScreen`を作り、購入・復元・アラート・エラーの記録をつなぐ
- [ ] 文言の英訳を入れ、`make check-translations`を通す
- [ ] `AppRoute.paywall`に`isPlanChange`を足し、`SubscriptionManagementView`から使う
- [ ] `SubscriptionManagementScreen`を足し、`PaywallGate`で出し分ける
- [ ] `PaywallScreen.swift`（RevenueCatUI）を消し、`RevenueCatUI`の依存を外す
- [ ] `.prefire.yml`と`hometeVRT.xcodeproj`に`PaywallFeature`を足す

### Phase 2.5: ドキュメント

- [ ] ADR-0006を置き換えるADRを書く（番号はhomete_backendの`docs/adr/`と照らして最大+1。今のiOS側の最大は0067）。「訴求内容は機能のリリースと連動するため、コードで持つほうが同期できる」を判断理由として残す。ADR-0006の状態をSupersededにする
- [ ] `doc/multimodules_structure.md`に`PaywallFeature`を足す
- [ ] `doc/premium_plan.md`の「2.3 訴求が露出する導線」と「3. 論点」を、Paywallの文言がコードにある前提に直す
- [ ] `doc/analytics_events.md`の`screen_view`の表の`paywall`の行（付けている場所）を直す
- [ ] `.claude/rules/ux-writing.md`・`screen-view-tracking.md`のRevenueCat Paywallへの言及を直す（`chore:`で別コミット）

### Phase 3: 検証

- [ ] `make build-affected` でビルド通過（InfraPackageも含む）
- [ ] `swift-code-verification` スキルに沿って SwiftLint 通過
- [ ] `make test-affected` でユニットテスト通過
- [ ] `make check-previews` 通過
- [ ] `make snapshot-affected` でPaywallFeatureのVRTが通る（参照スナップショットの更新はCI）
- [ ] Stg環境（Sandbox / TestFlight）で購入・リストア・キャンセル・プラン変更が動く
- [ ] 購入の失敗・プラン一覧の取得の失敗がCrashlyticsに非致命イベントとして届く

### Phase 4: PR

- [ ] PR作成（`pr-create` スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ
- [ ] 置き換え後のバージョンが行き渡ったら、RevenueCatダッシュボードのPaywalls設定を整理する（別作業）

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/404
- 関連ADR: [ADR-0004](../adr/0004-revenuecat-sdk-adoption.md)（RevenueCat SDKの採用）、[ADR-0006](../adr/0006-revenuecatui-paywall-adoption.md)（RevenueCatUIの採用。今回置き換える対象）
- 既存実装（参考）:
  - `InfraPackage/Sources/AppRoot/ResolverImpl/AccountLinkRoutes.swift`（`PaywallGate`）
  - `InfraPackage/Sources/HometeInfrastructure/Purchase/PaywallScreen.swift`
  - `LocalPackage/Sources/HometeDomain/Subscription/SubscriptionStore.swift`
  - `LocalPackage/Sources/Features/SettingFeature/SubscriptionManagement/SubscriptionManagementView.swift`
  - `LocalPackage/Sources/Features/AuthFeature/Onboarding/PremiumIntroductionView.swift`（訴求文言のお手本）
  - `doc/premium_plan.md`
