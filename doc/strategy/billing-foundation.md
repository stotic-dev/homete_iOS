# 課金実装の基盤構築 実装方針

> 関連Issue: [#178 課金実装の基盤構築](https://github.com/stotic-dev/homete_iOS/issues/178)
> 関連ADR: [ADR-0002 課金基盤の実装に RevenueCat を採用する](../adr/0002-billing-revenuecat.md)
> ブランチ: `feat/billing`

## ステータス

- [x] 要件確定
- [x] 設計確定
- [ ] 実装完了
- [ ] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

プレミアムプラン導入の前段として、RevenueCat iOS SDK を用いた課金基盤を構築する。
本Issueでは「SDK統合」と「現在のプレミアム加入状態を取得できるドメインモデル / Client の整備」までを担い、購入フロー・購入画面UIは別Issueとして切り出す。

## スコープ

### 含むもの

- RevenueCat iOS SDK の Swift Package 統合
- `HometeDomain/Billing/` の新設（`PlanContext` / `PremiumPlan` / `BillingClient`）
- `HometeInfrastructure/Impl/ImplBillingClient.swift` の実装
- アプリ起動時の `Purchases.configure` 実行
- ログイン状態に応じた `Purchases.logIn(uid)` / `logOut()` の同期
- `PlanContext.isPremium(at:)` の判定ロジックとユニットテスト

### 含まないもの（別Issue化）

- 購入フロー（`Purchases.purchase(package:)` 呼び出し）
- Offerings 取得 API
- プレミアム購入画面 UI
- 復元購入の明示的 UI
- `CustomerInfo` 変更の AsyncStream 購読
- プレミアム機能の UI 出し分け実装

## 要件

### 機能要件

1. **SDK 設定**
   - アプリ起動時に `Purchases.configure(withAPIKey:)` を呼ぶ
   - Firebase の初期化と同じく `HometeApp` の起動シーケンスで実行
2. **ユーザー同期**
   - Firebase Auth のログイン完了時に `Purchases.shared.logIn(uid)` を呼ぶ
   - ログアウト時に `Purchases.shared.logOut()` を呼ぶ
   - 呼び出しタイミングは `RootView` の状態遷移（`launching` → `loggedIn` / `loggedIn` → `notLoggedIn`）
3. **状態取得**
   - `BillingClient.fetchCustomerInfo()` で RevenueCat の `CustomerInfo` を取得
   - そこから `PlanContext` を組み立てる
4. **プレミアム判定**
   - `PlanContext.isPremium(at: Date)` で判定可能
   - 月額/年額 Subscription: RevenueCat 側で管理する有効期限まで `true`
   - `OneTimeYearly`（買い切り型）: **購入日時 + 1年** まで `true`

### 非機能要件 / 制約

- 既存 DI パターン（`AppDependencies` への `BillingClient` 追加）に準拠
- Swift 6 strict concurrency 準拠（`Sendable` 適合）
- `HometeDomain` 側に SDK 依存を漏らさない（プロトコル抽象のみ）
- API キーは1つ（dev/prod 共通）。Sandbox / Production は StoreKit 側で判別される

## 設計方針

### 1. ドメインモデル: `PlanContext` / `PremiumPlan`

`LocalPackage/Sources/HometeDomain/Billing/` 配下に新規追加する。

```swift
// PremiumPlan.swift
public enum PremiumPlan: String, Sendable, Hashable {
    case monthlyPremium = "MonthlyPremium"
    case yearlyPremium  = "YearlyPremium"
    case oneTimeYearly  = "OneTimeYearly"

    public var isSubscription: Bool {
        switch self {
        case .monthlyPremium, .yearlyPremium: return true
        case .oneTimeYearly: return false
        }
    }
}
```

```swift
// PlanContext.swift
public struct PlanContext: Sendable, Equatable {

    public struct ActiveEntry: Sendable, Equatable {
        public let plan: PremiumPlan
        public let purchasedAt: Date      // 直近の購入日時
        public let expiresAt: Date?       // Subscription: RevenueCat の expirationDate / OneTime: purchasedAt + 1年
    }

    public let activeEntries: [ActiveEntry]

    public init(activeEntries: [ActiveEntry]) {
        self.activeEntries = activeEntries
    }

    /// 指定時刻に対してプレミアムが有効か
    public func isPremium(at date: Date = .now) -> Bool {
        activeEntries.contains { entry in
            guard let expiresAt = entry.expiresAt else { return true }
            return expiresAt > date
        }
    }

    /// 現在加入中のプラン（複数あれば優先度の高いもの）
    public func currentPlan(at date: Date = .now) -> PremiumPlan? {
        activeEntries
            .filter { entry in
                guard let expiresAt = entry.expiresAt else { return true }
                return expiresAt > date
            }
            .map(\.plan)
            .first
    }

    public static let inactive = PlanContext(activeEntries: [])
}
```

**OneTimeYearly のロジックポイント:**
RevenueCat の `EntitlementInfo.latestPurchaseDate` を `purchasedAt` に詰める。`expiresAt` は `purchasedAt + 1年`（`Calendar.current.date(byAdding: .year, value: 1, to: purchasedAt)`）。Subscription は RevenueCat の `expirationDate` をそのまま使う。

### 2. `BillingClient` プロトコル

`LocalPackage/Sources/HometeDomain/Dependencies/BillingClient.swift` に追加。

```swift
public struct BillingClient: DependencyClient, Sendable {

    public let configure: @Sendable () -> Void
    public let logIn: @Sendable (_ uid: String) async throws -> Void
    public let logOut: @Sendable () async throws -> Void
    public let fetchPlanContext: @Sendable () async throws -> PlanContext

    public init(
        configure: @Sendable @escaping () -> Void = {},
        logIn: @Sendable @escaping (_ uid: String) async throws -> Void = { _ in },
        logOut: @Sendable @escaping () async throws -> Void = {},
        fetchPlanContext: @Sendable @escaping () async throws -> PlanContext = { .inactive }
    ) {
        self.configure = configure
        self.logIn = logIn
        self.logOut = logOut
        self.fetchPlanContext = fetchPlanContext
    }
}

public extension BillingClient {
    static let previewValue = BillingClient()
}
```

### 3. `ImplBillingClient`（HometeInfrastructure）

`LocalPackage/Sources/HometeInfrastructure/Impl/ImplBillingClient.swift` に追加。

```swift
#if os(iOS)
    import HometeDomain
    import RevenueCat

    extension BillingClient {
        static let liveValue: BillingClient = .init(
            configure: {
                Purchases.logLevel = .warn
                Purchases.configure(withAPIKey: BillingConfig.apiKey)
            },
            logIn: { uid in
                _ = try await Purchases.shared.logIn(uid)
            },
            logOut: {
                _ = try await Purchases.shared.logOut()
            },
            fetchPlanContext: {
                let info = try await Purchases.shared.customerInfo()
                return PlanContext(customerInfo: info)
            }
        )
    }
#endif
```

`PlanContext.init(customerInfo:)` は `HometeInfrastructure` 側に extension として置くことで、`HometeDomain` を SDK 非依存に保つ。

### 4. API キー管理

- 共通キー1つを `BillingConfig.apiKey` に格納
- `homete/Config/` 等で xcconfig 経由で Info.plist に注入する形を採用予定（既存の Firebase 設定と同様に GitHub Secrets でも管理）
- **オープン事項**: Info.plist のキー名・xcconfig の具体的な置き場は実装時に確定

### 5. AppDependencies への組み込み

```swift
// AppDependencies.swift
public struct AppDependencies: Sendable {
    // ...既存
    public let billingClient: BillingClient

    public init(
        // ...既存
        billingClient: BillingClient = .previewValue
    ) {
        // ...
        self.billingClient = billingClient
    }
}
```

```swift
// AppDependencies+liveValue.swift
public extension AppDependencies {
    static let liveValue: Self = .init(
        // ...既存
        billingClient: .liveValue
    )
}
```

### 6. 初期化タイミング

| タイミング | 場所 | 呼び出し |
|---|---|---|
| アプリ起動 | `HometeApp.init` または `HometeApp` の `init` 直後 | `billingClient.configure()` |
| ログイン完了 | `RootView` で `LaunchState` が `loggedIn(context)` になった時 | `try await billingClient.logIn(uid)` |
| ログアウト | `RootView` で `loggedIn` → `notLoggedIn` への遷移時 | `try await billingClient.logOut()` |

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Billing/PremiumPlan.swift` | プラン enum |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Billing/PlanContext.swift` | プレミアム加入状態の値オブジェクト |
| 新規Client | `LocalPackage/Sources/HometeDomain/Dependencies/BillingClient.swift` | DI 用プロトコル |
| 新規実装 | `LocalPackage/Sources/HometeInfrastructure/Impl/ImplBillingClient.swift` | RevenueCat SDK ラッパー |
| 新規実装 | `LocalPackage/Sources/HometeInfrastructure/Impl/PlanContext+CustomerInfo.swift` | `CustomerInfo` → `PlanContext` マッピング |
| 修正 | `LocalPackage/Sources/HometeDomain/Dependencies/AppDependencies.swift` | `billingClient` プロパティ追加 |
| 修正 | `LocalPackage/Sources/HometeInfrastructure/AppDependencies+liveValue.swift` | `billingClient: .liveValue` 追加 |
| 修正 | `LocalPackage/Package.swift` | RevenueCat 依存追加 |
| 修正 | `LocalPackage/Sources/AppRoot/HometeApp.swift` 等 | 起動時 `configure` 呼び出し |
| 修正 | `LocalPackage/Sources/AppRoot/RootView/...` | ログイン/ログアウト時の同期 |
| 新規テスト | `LocalPackage/Tests/HometeDomainTests/PlanContextTest.swift` | `isPremium(at:)` のロジック検証 |

## タスク

### Phase 1: 設計確定

- [x] スコープ確定（SDK 統合 + 状態取得のみ）
- [x] SDK 配置先確定（`HometeInfrastructure`）
- [x] ドメインモデル設計確定（`PlanContext` + `PremiumPlan`）
- [x] AppUserID 連携方針確定（Firebase Auth uid）
- [x] ADR-0002 作成
- [ ] Info.plist / xcconfig での API キー格納方法の最終確定（実装時）

### Phase 2: 実装

- [ ] **T-1** `LocalPackage/Package.swift` に RevenueCat 依存追加
  - `https://github.com/RevenueCat/purchases-ios-spm` の最新タグ
  - `HometeInfrastructure` ターゲットに条件付き（iOS のみ）でリンク
- [ ] **T-2** `PremiumPlan` enum 実装
- [ ] **T-3** `PlanContext` 値オブジェクト + `isPremium(at:)` / `currentPlan(at:)` 実装
- [ ] **T-4** `BillingClient` プロトコル定義
- [ ] **T-5** `ImplBillingClient`（`.liveValue`）実装
- [ ] **T-6** `CustomerInfo` → `PlanContext` 変換ロジック実装（買い切りは購入日+1年）
- [ ] **T-7** API キー格納の仕組み（xcconfig / Info.plist / GitHub Secrets 連携）
- [ ] **T-8** `AppDependencies` への組み込み（Domain / Infrastructure 両方）
- [ ] **T-9** `HometeApp` 起動時の `configure()` 呼び出し
- [ ] **T-10** `RootView` の `loggedIn` / `notLoggedIn` 遷移での `logIn` / `logOut` 呼び出し

### Phase 3: 検証

- [ ] **T-11** `PlanContext` のユニットテスト追加（`HometeDomainTests`）
  - 加入なし → `isPremium` が `false`
  - Monthly Subscription: `expiresAt` 前後で結果が変わる
  - Yearly Subscription: 同上
  - OneTimeYearly: 購入日 + 1年 を境界に結果が変わる
  - 複数 entry がある場合に最も将来の `expiresAt` を採用 / もしくは「いずれかが有効」なら true
  - `currentPlan(at:)` が期待通り
- [ ] **T-12** `swift-code-verification` スキルに従ったビルド・SwiftLint・ユニットテスト実行
- [ ] **T-13** Sandbox ユーザーで実機検証（手動: ログイン → CustomerInfo 取得が成功すること）

### Phase 4: PR

- [ ] **T-14** `pr-create` スキルで PR 作成
- [ ] **T-15** Danger / CI 通過
- [ ] **T-16** レビュー対応・マージ

## オープン事項

実装中に判断が必要になった場合に追記する。

- **API キーの格納方式**: xcconfig + Info.plist で進める想定だが、最終形は実装時に確定する
- **`BillingConfig` の置き場**: `HometeInfrastructure` 内で完結させるか、`homete/Config/` 配下で外出しするか
- **AsyncStream 購読 / Offerings 取得 API**: 本 Issue のスコープ外。プレミアム購入画面 UI 実装の Issue で別途追加

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/178
- ADR: [doc/adr/0002-billing-revenuecat.md](../adr/0002-billing-revenuecat.md)
- 既存類似実装（参考）:
  - `LocalPackage/Sources/HometeDomain/Advertisement/` — 外部SDK系ドメインモデルの配置例
  - `LocalPackage/Sources/HometeInfrastructure/Impl/ImplAnalyticsClient.swift` — 静的設定型 Client の `liveValue` 実装パターン
  - `LocalPackage/Sources/HometeInfrastructure/Impl/ImplAccountAuthClient.swift` — Firebase Auth 連携の参考
