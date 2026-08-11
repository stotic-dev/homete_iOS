# プレミアム会員向け家事データ保存期間の無制限化 実装方針

> 関連Issue: [#197 Feature: プレミアム会員向け家事データ保存期間の無制限化](https://github.com/stotic-dev/homete_iOS/issues/197)
> ブランチ: `feat/preminu-benefit-storage`
> 関連Issue: [#194 Paywall基盤実装と設定画面導線](https://github.com/stotic-dev/homete_iOS/issues/194), [#178 課金実装の基盤構築](https://github.com/stotic-dev/homete_iOS/issues/178), [#158 課金実装で開放する機能の検討](https://github.com/stotic-dev/homete_iOS/issues/158)

## ステータス

- [x] 要件確定
- [x] 設計確定
- [x] 実装完了
- [x] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

プレミアムプランの提供価値として「家事データの保存期間無制限化」を実現する。

現状は無料/プレミアムの区別なく全ユーザー一律で「登録日+1年」の保存期間になっている。本対応では**無料版の上限を新設**（閲覧: 直近3ヶ月 / 保持: 登録日+1年）し、**プレミアムは閲覧・保持ともに無制限**とする。既存動作を変更するため、データ消失リスクを最小化する設計を優先する。

## 前提調査の結果

実装着手前の調査で、Issue 記載の前提と実装の実態に差異が2点あった。設計はこの調査結果に基づく。

### 1. 家事ボードは現状±7日しか閲覧できない

`HouseworkDateList`（`LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkDateList.swift:23-24`）が `selectableOffset = 7` / `unselectablePadding = 3` を持ち、日付セルは基準日±10日分（21セル）しか生成されない。`selectDate` も `isSelectable` で±7日にガードされている。

そのため「保存期間外の過去日付を閲覧しようとする」状況は**現状の家事ボードでは発生し得ない**。本対応では家事ボードの過去方向の範囲を拡張したうえでブロック表示を置く（後述）。

### 2. 保存期間が実際に効いているのは貢献度画面

`AnalyticsPeriodHeader`（`.../ContributionFeature/View/Analytics/SubViews/AnalyticsPeriodHeader.swift:103`）の `shiftPeriod(by: -1)` は過去方向に**上限なし**でシフトできる。一方データ供給元の `HouseworkManager.allItems` は直近1年分しかないため、1年より前に遡ると無言で空グラフになる。ここが実質的な保存期間の体感点であり、ブロック表示の主戦場となる。

### 3. Firestore TTL の設定はリポジトリ上に存在しない

- `firebase/firestore.indexes.json` の `fieldOverrides` は空配列
- `firebase/functions/src/` に削除バッチ・スケジュール関数は存在しない（`notifyCohabitants` / `deleteUserData` のみ）
- 一方 `doc/strategy/housework-points.md:191` には「`expiredAt` は Firestore TTL（自動削除）に使用されている」と記述あり

**TTLポリシーは Firebase コンソール側の手動設定に依存している**と判断される。着手前にユーザーへ確認し、**TTLは設定済み**であることを確認済み（2026-08-11）。したがって `expiredAt` の変更はそのまま実データの削除タイミングに反映される。

### 4. Firestore のデータ構造

家事データは同居人グループ配下にフラットに置かれる。

```
Cohabitant/{cohabitantId}/Houseworks/{houseworkItemId}
  - indexedDate.value: Timestamp  # 家事の日付（クエリキー）
  - expiredAt: Timestamp          # TTL対象フィールド
```

`ImplHouseworkClient`（`LocalPackage/Sources/AppRoot/Dependency/Impl/ImplHouseworkClient.swift:36-41`）の `fetchItems` は `indexedDate.value` の範囲クエリで取得している。

## 要件

### 機能要件

#### 保存期間の定義

| 区分 | 閲覧可能範囲 | Firestore上の保持期間（`expiredAt`） |
|---|---|---|
| 無料 | 直近3ヶ月 | 家事の登録日 + 1年（現状維持） |
| プレミアム | 無制限 | 無制限（実質無期限） |

- 保持期間は**同居人グループ単位**で決まる。グループ内に1人でもプレミアム会員がいれば、そのグループの家事データ全件が無期限保持になる
- 閲覧制限は**個人単位**で判定する。プレミアム会員がいるグループでも、無料メンバー自身の閲覧範囲は直近3ヶ月のまま

#### 画面別の閲覧範囲とブロック表示

| 画面 | 無料ユーザー | プレミアムユーザー |
|---|---|---|
| 家事ボード | 過去30日 〜 未来7日 | 過去は無制限（フェッチ済み範囲） 〜 未来7日 |
| 貢献度（分析） | 直近3ヶ月まで遡れる | 無制限に遡れる |

- 無料ユーザーが上限を超えて遡ろうとした場合、空状態表示＋「プレミアムプランに登録すると全期間閲覧できます」のCTAを出し、タップで Paywall（`AppRoute.paywall`）へ遷移させる
- 家事ボードの未来方向は現状の+7日を維持する（プラン非依存）

#### プラン変更時のデータ挙動

| イベント | 挙動 |
|---|---|
| プレミアム加入 | グループの家事データ全件の `expiredAt` を無期限に延長（Cloud Function で一括更新） |
| プレミアム解約 | グループの家事データ全件の `expiredAt` を**解約日+1年**に短縮（Cloud Function で一括更新） |

- 解約時の基準日は「家事の登録日」ではなく**解約日**とする。登録日基準にすると解約した瞬間に1年以上前のデータが一斉にTTL削除対象になるため
- 解約の検知はクライアント起動時のエンタイトルメント状態に依存する。アプリを起動しない限り短縮は走らない（データが余分に残るだけでユーザー不利益はないため許容する）

### 非機能要件 / 制約

- `isPremium` の取得は既存の `SubscriptionStore`（`LocalPackage/Sources/HometeDomain/Subscription/SubscriptionStore.swift`）を使う。`@MainActor @Observable` であり、`HouseworkManager` は `actor` なので、境界をまたぐ値渡しで設計する
- 既存DIパターン（`AppDependencies` 経由）に準拠する
- Swift 6 strict concurrency 準拠
- `expiredAt` の変更はデータ削除に直結するため、Domain層のロジックはユニットテストで境界値を必ず押さえる
- 貢献度画面のオンデマンドフェッチにより `HouseworkManager` が取得済み期間を管理する必要がある。既存の `allItems` 単純保持から状態が増えるため、責務を明示する

### スコープ外

- 「まもなくデータが閲覧できなくなります」等の事前通知
- RevenueCat Webhook によるサーバー主導の解約検知（クライアント起動時検知で代替）
- 家事ボードの未来方向の範囲拡張

## 設計方針

### 1. 保存期間のドメインモデル新設

`LocalPackage/Sources/HometeDomain/Subscription/` に保存期間ポリシーを表す型を追加し、期間の定義を1箇所に集約する。ビューもマネージャーもこの型を参照する。

```swift
// HouseworkStoragePolicy.swift
import Foundation

/// プランごとの家事データの保存期間ポリシー
public enum HouseworkStoragePolicy: Equatable, Sendable {

    case free
    case premium

    public init(isPremium: Bool) {
        self = isPremium ? .premium : .free
    }

    /// 閲覧可能な最古の日付。プレミアムはnil（無制限）
    public func viewableLowerBound(from currentDate: Date, calendar: Calendar) -> Date? {
        switch self {
        case .free:
            calendar.date(byAdding: .month, value: -Self.freeViewableMonths, to: calendar.startOfDay(for: currentDate))

        case .premium:
            nil
        }
    }

    /// 指定日が閲覧可能範囲内か
    public func isViewable(_ date: Date, currentDate: Date, calendar: Calendar) -> Bool {
        guard let lowerBound = viewableLowerBound(from: currentDate, calendar: calendar) else { return true }
        return calendar.startOfDay(for: date) >= lowerBound
    }

    /// 家事ボードで遡れる日数。プレミアムはnil（無制限）
    public var boardBackwardDays: Int? {
        switch self {
        case .free: Self.freeBoardBackwardDays
        case .premium: nil
        }
    }

    private static let freeViewableMonths = 3
    private static let freeBoardBackwardDays = 30

}
```

`expiredAt` の算出も同じ型に持たせる。

```swift
public extension HouseworkStoragePolicy {

    /// 家事データの保持期限を算出する
    /// - Parameter baseDate: 無料プランでの起点（家事の登録日、もしくは解約日）
    func expiredAt(from baseDate: Date, calendar: Calendar) -> Date {
        switch self {
        case .free:
            calendar.date(byAdding: .year, value: Self.freeRetentionYears, to: baseDate) ?? baseDate

        case .premium:
            // TTLによる自動削除が実質発生しない十分先の日付
            calendar.date(byAdding: .year, value: Self.premiumRetentionYears, to: baseDate) ?? baseDate
        }
    }

    private static var freeRetentionYears: Int { 1 }
    private static var premiumRetentionYears: Int { 100 }
}
```

> `.distantFuture` ではなく「+100年」を使う。`.distantFuture` は Firestore の Timestamp 表現可能範囲を超えるため。

### 2. `DailyHouseworkMetaData` の `expiredAt` 算出をプラン依存にする

現状（`.../Housework/DailyHouseworkMetaData.swift:22-29`）は一律で+1年。ポリシーを引数で受け取る形に変更する。

```swift
public extension DailyHouseworkMetaData {

    init(selectedDate: Date, calendar: Calendar, storagePolicy: HouseworkStoragePolicy) {
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let indexedDate = HouseworkIndexedDate(value: selectedDay)
        self.init(
            indexedDate: indexedDate,
            expiredAt: storagePolicy.expiredAt(from: selectedDay, calendar: calendar)
        )
    }

}
```

呼び出し元は `DailyHouseworkList.makeInitialValue` 経由の2箇所。

- `.../HomeFeature/HomeView/SubViews/RegisteredContent/Components/TodayHouseworkSummaryComponent.swift:37`
- `.../HouseworkFeature/HouseworkBoardView/HouseworkBoardView.swift:75`

いずれも `@Environment(SubscriptionStore.self)` を参照できる位置にあるため、`storagePolicy` を渡す。

### 3. `HouseworkManager` のフェッチ範囲をプラン依存＋オンデマンド化

`setupObserver`（`.../Housework/HouseworkManager.swift:49-72`）の一律1年フェッチを変更する。

- 起動時: 無料は直近3ヶ月、プレミアムは直近1年をワンショット取得
- 貢献度画面で取得済み範囲より過去へ遡られたら、不足分を追加フェッチしてマージする

取得済み範囲を管理する状態を `HouseworkManager` に追加する。

```swift
public final actor HouseworkManager {

    public private(set) var allItems: [HouseworkItem] = []
    /// フェッチ済みの期間。この範囲外はまだ取得していない
    public private(set) var fetchedRange: ClosedRange<Date>?

    // ...

    public func setupObserver(
        currentTime: Date,
        cohabitantId: String,
        calendar: Calendar,
        storagePolicy: HouseworkStoragePolicy
    ) async {
        // 初期フェッチ範囲をポリシーから決める
    }

    /// 指定日まで遡れるように不足分を追加フェッチする
    /// - Returns: 追加取得が発生したか
    @discardableResult
    public func fetchIfNeeded(
        until targetDate: Date,
        cohabitantId: String,
        calendar: Calendar
    ) async -> Bool {
        guard let fetchedRange, targetDate < fetchedRange.lowerBound else { return false }
        // targetDate 〜 fetchedRange.lowerBound を取得して upsert し fetchedRange を広げる
    }

}
```

`upsert` は既存の実装（`HouseworkManager.swift:80-86`）をそのまま流用できる。同時多重フェッチを避けるため、`fetchIfNeeded` は actor 隔離のまま進行中タスクを保持して重複要求を待ち合わせる。

### 4. 貢献度画面のブロック表示

`AnalyticsPeriodHeader` の左シフト（`.../AnalyticsPeriodHeader.swift:103`）に上限判定を追加し、`ContributionAnalyticsView` に空状態を出す。

- 左シフトボタンは、シフト後の期間が閲覧可能範囲を完全に外れる場合も**押せる状態のまま**にする（押せないと理由が伝わらないため）
- シフト後に閲覧可能範囲外へ出たら、グラフの代わりにブロック表示を出す

```swift
// ContributionAnalyticsView.swift の分岐に追加
if !storagePolicy.isViewable(periodLowerBound, currentDate: now, calendar: calendar) {
    StoragePeriodLimitView(onUpgradeTapped: { router.resolve(.paywall) })
} else if let analytics {
    // 既存の分岐
}
```

プレミアムユーザーの場合は、シフト時に `HouseworkManager.fetchIfNeeded(until:)` を呼んでデータを補充する。

### 5. 家事ボードの範囲拡張とブロック表示

`HouseworkDateList` を過去方向だけプラン依存に変える。

```swift
struct HouseworkDateList: Equatable {

    // 未来方向は据え置き
    private static let forwardSelectableOffset = 7
    private static let unselectablePadding = 3

    init(
        anchorDate: Date = .now,
        selectedDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent,
        backwardSelectableDays: Int   // 無料: 30 / プレミアム: フェッチ済み範囲までの日数
    )

}
```

**描画への影響**: `HouseworkDateHeaderContent`（`.../SubViews/DateHeader/HouseworkDateHeaderContent.swift:29-37`）は `ScrollView` 内で非Lazyな `HStack` + `ForEach` を使っている。現状21セルなので問題ないが、30日超（無料で最大41セル、プレミアムはさらに多い）になるため **`LazyHStack` へ変更する**。`scrollTargetLayout` / `visualEffect` / `ScrollViewReader.scrollTo` は `LazyHStack` でも機能するが、初回表示時のスクロール位置決めが遅延生成の影響を受けやすいため、`defaultScrollAnchor` の併用も含めて実装時に挙動確認する。

過去端のセルには「これ以前を見るにはプレミアムプラン」のブロックセルを置き、タップで Paywall へ遷移させる。

### 6. プラン変更時の `expiredAt` 一括更新（Cloud Function）

`firebase/functions/src/syncHouseworkRetention.ts` を新規追加する。既存の `notifyCohabitants.ts`（`onCall` v2 + 認証チェック）と同じパターンに揃える。

```typescript
interface SyncHouseworkRetentionRequest {
  cohabitantId: string;
}

// 呼び出し元の現在のプランをサーバー側で解決し、
// Cohabitant/{cohabitantId}/Houseworks 配下の expiredAt を一括再計算する
export const synchouseworkretention = onCall(async (request) => { /* ... */ });
```

**処理内容:**

1. 認証チェック（`request.auth` 必須）
2. 呼び出し元が当該 `cohabitantId` のメンバーであることを検証
3. グループメンバー全員のプレミアム状態を解決し、1人でもプレミアムなら「グループはプレミアム」と判定
4. `Houseworks` 配下を500件ずつ `BulkWriter` / バッチで走査し `expiredAt` を再計算して更新
   - グループがプレミアム: 各家事の `indexedDate.value` + 100年
   - グループが無料: **実行日（解約日相当）+ 1年**。ただし既存の `expiredAt` がそれより手前なら据え置く
5. 冪等に実装する（加入時・解約時とも同じ関数で「現在のプラン基準に揃える」処理にする）

> 無料時に既存の期限を延ばさないのは、実行日起点のままだと呼ぶたびに期限が伸びて冪等でなくなるため。グループのメンバーが繰り返し呼ぶだけでTTLによる削除を無期限に先送りできてしまう。

**プレミアム状態のサーバー側解決**: RevenueCat の状態はサーバーが直接持っていない。`Account` ドキュメントにプレミアム状態を書き込む必要があるため、`AuthSubscriptionSyncUseCase`（`LocalPackage/Sources/HometeDomain/UseCase/AuthSubscriptionSyncUseCase.swift`）でエンタイトルメント同期時に `Account.isPremium` を保存する形にする。Function はこのフィールドを参照してグループ判定を行う。

> この `Account.isPremium` はクライアント書き込みになるため、Firestore Rules で「自分のドキュメントのみ書き込み可」を担保する。改竄されてもデータ保持期間が延びるだけで課金機能の解放には繋がらない（閲覧制限はクライアントのエンタイトルメント判定に依存）ため、リスクは限定的と判断する。

**呼び出しタイミング**: `AuthSubscriptionSyncUseCase.syncHouseworkRetentionIfNeeded()` が「同期済みの `(cohabitantId, isPremium)`」と現在の状態を突き合わせ、**差分があるときだけ** Function を呼ぶ。呼び出し元は次の3箇所。

- `RootView` の `.onChange(of: subscriptionStore.isPremium)` — 起動中のプラン変更を拾う
- `syncOnSignedIn` / `syncOnRegistered` — アプリ未起動の間に失効したケースは状態変化として検知できないため、サインイン時にも突き合わせる
- `RootView` の `.onChange(of: accountStore.account)` — グループへの参加はアカウント更新として届くため、参加後の同期をここで拾う

同期の完了状態は `Account.isPremium` の更新有無ではなく、`HouseworkRetentionSyncStateStore`（端末の `UserDefaults`）に独立して記録する。`Account.isPremium` の差分だけを条件にすると、**グループ未参加のままプレミアムになった場合**や**Function の呼び出しに失敗した場合**にプレミアム状態だけが先に確定してしまい、以降の呼び出しが「差分なし」で素通りして二度と同期されなくなるため。記録は同期成功時のみ残すことで、未完了なら次の起動・プラン変更で必ずやり直す。

### 7. 保存期間ポリシーのView階層への配布

各Viewが `SubscriptionStore` を直接参照すると、Preview やスナップショットテストで毎回Storeを差し込む必要が出るため、`EnvironmentValues` に `houseworkStoragePolicy` を追加して配布する。

```swift
// HometeDomain/Utilities/Environments.swift
public extension EnvironmentValues {
    @Entry var houseworkStoragePolicy = HouseworkStoragePolicy.free
}
```

`AppTabView` で `SubscriptionStore.isPremium` から組み立てて注入する。デフォルトが `.free` なので、注入し忘れても保存期間が意図せず伸びることはない（安全側に倒れる）。

### 8. `Account` へのプレミアム状態の永続化

`Account` に `isPremium: Bool` を追加する。既存ドキュメントにはこのフィールドが存在しないため、`init(from:)` を手書きして `decodeIfPresent ?? false` でフォールバックする（デコード失敗でアカウントが読めなくなるのを防ぐ）。

メモリ化された `Account` を組み替えている `AccountStore.updateFcmTokenIfNeeded` / `registerCohabitantId` は `isPremium` を引き継ぐようにする（引き継ぎ漏れがあるとFCMトークン更新のたびに無料へ戻ってしまう）。

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Subscription/HouseworkStoragePolicy.swift` | 保存期間ポリシー（閲覧範囲・`expiredAt` 算出） |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Account/Account.swift` | `isPremium` 追加とデコード時のフォールバック |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Account/AccountStore.swift` | `isPremium` の引き継ぎと更新 |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Utilities/Environments.swift` | `houseworkStoragePolicy` の Environment 追加 |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/HouseworkTemplate/HouseworkTemplateDay.swift` | テンプレート展開時の `expiredAt` をポリシー依存に |
| 修正AppRoot | `LocalPackage/Sources/AppRoot/AppTabView.swift` | ポリシーの注入 |
| 修正AppRoot | `LocalPackage/Sources/AppRoot/RootView.swift` | プラン変化検知と同期の起動 |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/DailyHouseworkMetaData.swift` | `expiredAt` 算出をポリシー依存に |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/DailyHouseworkList.swift` | `makeInitialValue` にポリシーを引き回す |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkManager.swift` | フェッチ範囲のプラン依存化・オンデマンド追加フェッチ |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/UseCase/AuthSubscriptionSyncUseCase.swift` | `Account.isPremium` 同期とFunction呼び出しトリガー |
| 修正Client | `LocalPackage/Sources/HometeDomain/Dependencies/HouseworkClient.swift` | 保持期間同期API（Function呼び出し）を追加 |
| 新規実装 | `LocalPackage/Sources/AppRoot/Dependency/Impl/ImplHouseworkClient.swift` | 同期API の `liveValue` 実装 |
| 修正View | `.../Features/HouseworkFeature/Model/HouseworkDateList.swift` | 過去方向の範囲をプラン依存に |
| 修正View | `.../HouseworkBoardView/SubViews/DateHeader/HouseworkDateHeaderContent.swift` | `LazyHStack` 化・ブロックセル追加 |
| 修正View | `.../HouseworkBoardView/HouseworkBoardView.swift` | ポリシー注入・Paywall導線 |
| 新規View | `.../Features/ContributionFeature/View/Analytics/SubViews/StoragePeriodLimitView.swift` | 保存期間外の空状態＋Paywall CTA |
| 修正View | `.../Features/ContributionFeature/View/Analytics/ContributionAnalyticsView.swift` | ブロック表示の分岐追加 |
| 修正View | `.../Features/ContributionFeature/View/Analytics/SubViews/AnalyticsPeriodHeader.swift` | 上限判定・オンデマンドフェッチ起動 |
| 修正View | `.../Features/HomeFeature/HomeView/HomeView.swift` | `setupObserver` にポリシーを渡す |
| 新規Function | `firebase/functions/src/syncHouseworkRetention.ts` | callable本体（認証・メンバー検証・プラン判定） |
| 新規Function | `firebase/functions/src/models/HouseworkRetentionUpdater.ts` | `expiredAt` の一括再計算（テスト容易性のため分離） |
| 新規Function | `firebase/functions/src/models/HouseworkRetention.ts` | 保持期限の定数と算出ロジック |
| 修正Function | `firebase/functions/src/index.ts` | 新規Functionのexport |
| 修正Function | `firebase/functions/src/models/Account.ts` | `isPremium` フィールド追加 |
| 修正Function | `firebase/functions/src/models/FirestoreCollections.ts` | `Houseworks` サブコレクション追加 |
| 新規テスト | `LocalPackage/Tests/HometeDomainTests/Subscription/HouseworkStoragePolicyTest.swift` | 閲覧範囲・`expiredAt` の境界値 |
| 修正テスト | `LocalPackage/Tests/HometeDomainTests/Housework/HouseworkManagerTest.swift` | プラン別フェッチ範囲・追加フェッチ |
| 新規テスト | `firebase/functions/test/` | Function のE2Eテスト |

## タスク

### Phase 0: 前提確認（実装着手前の必須確認）

- [x] **T-0** `expiredAt` の TTL ポリシーが設定済みであることをユーザーに確認（2026-08-11）
- [ ] **T-0-2** 本番環境の既存データ件数を概算し、一括更新のコスト影響を見積もる（デプロイ前）

### Phase 1: 設計確定

- [x] 無料版の保存期間上限を確定（閲覧: 直近3ヶ月 / 保持: 登録日+1年）
- [x] 制限方式を確定（無料は閲覧制限。実削除は無料の既存ルール1年を維持）
- [x] ブロックUIの配置を確定（貢献度画面＋家事ボード両方）
- [x] 家事ボードの範囲を確定（無料は過去30日 / プレミアムは無制限）
- [x] プレミアムのフェッチ方式を確定（起動時＋オンデマンド追加フェッチ）
- [x] アップグレード時の延長方式を確定（Cloud Function で一括更新）
- [x] 解約時の扱いを確定（解約日+1年に短縮）
- [x] グループ内の混在時の扱いを確定（1人でもプレミアムならグループ全体を無期限）
- [x] `Account.isPremium` のFirestore同期方式を確定（クライアント書き込み + デコード時フォールバック）

### Phase 2: 実装（Domain）

- [x] **T-1** `HouseworkStoragePolicy` を新規実装（閲覧範囲・`expiredAt` 算出）
- [x] **T-2** `DailyHouseworkMetaData` / `DailyHouseworkList` をポリシー依存に変更
- [x] **T-3** `HouseworkManager` に `fetchedRange` とプラン依存の初期フェッチを実装
- [x] **T-4** `HouseworkManager.fetchIfNeeded(until:)` を実装（重複要求の待ち合わせ含む）
- [x] **T-5** `HouseworkClient` に保持期間同期APIを追加し `liveValue` を実装
- [x] **T-6** `AuthSubscriptionSyncUseCase` に `Account.isPremium` 同期とプラン変化検知を実装

### Phase 3: 実装（UI）

- [x] **T-7** `HouseworkDateList` の過去方向をプラン依存に変更
- [x] **T-8** `HouseworkDateHeaderContent` を `LazyHStack` 化
- [x] **T-9** 家事ボードの過去端にブロックセル＋Paywall導線を追加
- [x] **T-10** `StoragePeriodLimitView` を新規実装（空状態＋CTA）
- [x] **T-11** `ContributionAnalyticsView` / `ContributionAnalyticsScreen` に上限判定とオンデマンドフェッチ起動を実装
- [x] **T-12** `HomeView` の `setupObserver` 呼び出しにポリシーを渡す
- [x] **T-13** Preview の追加・修正（無料/プレミアム、上限内/上限外の組み合わせ）

### Phase 4: 実装（Firebase）

- [x] **T-14** `syncHouseworkRetention.ts` / `HouseworkRetentionUpdater.ts` を実装（冪等な一括再計算）
- [x] **T-15** `index.ts` へのexport追加
- [x] **T-16** `firestore.rules` の扱いを決定 → **変更なし**（下記「見送った項目」参照）
- [ ] **T-17** TTLポリシーの設定内容（削除猶予・対象フィールド）をドキュメント化

### Phase 5: 検証

- [x] **T-18** `HouseworkStoragePolicyTest` を追加（境界値: ちょうど3ヶ月前/1日前、`expiredAt` の算出）
- [x] **T-19** `HouseworkManagerTest` を更新（プラン別の初期フェッチ範囲、追加フェッチのマージ、取得済み期間のスキップ）
- [x] **T-20** Cloud Function のテストを追加（加入時の延長、解約時の短縮、冪等性、520件のバッチ分割、グループ判定）
- [x] **T-21** `make build-local-package` でビルド通過
- [x] **T-22** SwiftLint 通過（新規警告ゼロ）
- [x] **T-23** `make test-packages` でユニットテスト通過（252件）
- [ ] **T-24** スナップショットテスト（新規Preview 4件の参照画像生成）— Xcode Cloud の `VRT` ワークフローで実施
- [x] **T-25** `npm run lint` / `npm run test:e2e` で Functions 検証（15件通過）
- [ ] **T-26** 実機でSandboxユーザーによる加入→解約の一連動作確認

## 見送った項目

### `firestore.rules` での `Account.isPremium` 書き込み制限（T-16）

当初の設計では「自分のドキュメントのみ書き込み可」に制限する予定だったが、**実装しても効果がないため見送った**。

現在の `firestore.rules` は以下の1ルールのみで構成されている。

```
match /{document=**} {
  allow read, write: if request.auth != null;
}
```

Firestore のセキュリティルールは複数の `match` を **OR** で評価するため、この包括ルールが残っている限り `/Account/{id}` に厳しいルールを足しても素通りする。実効性を持たせるには包括ルールを廃してコレクションごとに書き直す必要があり、既存の全書き込み経路に影響する。これは本Issueのスコープを超える独立した変更のため、別Issueとして切り出すのが適切と判断した。

なお `Account.isPremium` が改竄された場合の影響は「家事データの保持期間が伸びる」ことに限られる。プレミアム機能の解放判定はクライアントのエンタイトルメント（RevenueCat）で行っており、この値は参照していないため、機能の不正解放には繋がらない。

### Phase 6: PR

- [ ] **T-27** PR作成（`pr-create` スキル使用）
- [ ] **T-28** Danger / CI通過
- [ ] **T-29** レビュー対応（データ削除に関わるため重点レビュー）
- [ ] **T-30** マージ

## リスクと対策

| リスク | 影響 | 対策 |
|---|---|---|
| TTLが実は未設定で、`expiredAt` の変更が無意味 | 実装が空振り | Phase 0 の T-0 で着手前に確認する |
| 解約時の一括短縮でデータが意図せず削除される | **不可逆なデータ消失** | 基準日を解約日とし1年の猶予を設ける。Function にドライラン相当のログを仕込み、STG環境で件数を検証してから本番反映 |
| `Account.isPremium` の改竄 | 保持期間の不正延長 | 現状のRulesでは制限できない（「見送った項目」参照）。影響は保持期間の延長のみで、機能解放はクライアントのエンタイトルメント判定に依存するため実害は限定的 |
| プレミアムの全期間フェッチによる起動遅延 | 起動時間の悪化 | 起動時は直近1年に留め、それ以前はオンデマンド取得にする |
| `LazyHStack` 化によるスクロール位置ずれ | 家事ボードの初期表示崩れ | T-8 で実機確認。必要なら `defaultScrollAnchor` を併用 |

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/197
- 既存実装（参考）:
  - `doc/strategy/billing-foundation.md` — 課金基盤の設計方針
  - `doc/strategy/housework-points.md` — `expiredAt` を1年に延長した際の経緯（L191）
  - `LocalPackage/Sources/HometeDomain/Subscription/SubscriptionStore.swift` — `isPremium` の取得元
  - `firebase/functions/src/notifyCohabitants.ts` — callable Function の実装パターン
