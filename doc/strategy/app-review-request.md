# アプリ評価のリクエスト 実装方針

> 関連Issue: [#362 良きタイミングでアプリ評価レビューを出す](https://github.com/stotic-dev/homete_iOS/issues/362)
> ブランチ: `feat/362-app-review`

## ステータス

- [x] 要件確定
- [x] 設計確定
- [ ] 実装完了
- [ ] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

ユーザーがアプリの価値を感じたと考えられるタイミングで、OS標準の評価ダイアログ（`requestReview`）を出す。
価値を感じたタイミングは「課金した直後」と「同居人からありがとうを受け取ったとき（使い込んでいると判断できる条件付き）」の2系統にする。

## 要件

### 機能要件

#### トリガー

| トリガー | 条件 | Analyticsの`trigger` |
|---|---|---|
| A: 課金 | プランを取得済みで無料プランだった状態から、プレミアムプランに変わった（購入・復元のどちらでも） | `purchase` |
| C: ありがとうの合計 | アップデート後に受け取ったありがとうの合計が**10回以上**になった | `thanks_count` |
| D: 使い始めて2週間 | 使い始めてから**14日以上**たってから、ありがとうを受け取った | `thanks_after_two_weeks` |

- 「ありがとうを受け取った」とは、自分が担当者（`executors`）に含まれる家事に、自分以外の人からありがとうが届いたこと。代わりに記録してもらった家事も含む
- C・Dで数えるのは、**この機能が入ったバージョンで初めて起動した後に届いたありがとうだけ**。それより前に届いていたものは数えない
- Dの「使い始めた日」は、この機能が入ったバージョンで初めて起動した日とする。`Account`に作成日がないため。既存ユーザーはアップデートしてから14日後にDの対象になる。再インストールするとリセットされる
- 評価ダイアログはOS標準のものをそのまま使う（アプリ独自の確認ダイアログは挟まない）

#### 出すタイミング

- A: プランが変わったことを検知してから少し待って出す。RevenueCatのペイウォールは購入すると自動で閉じる（`PaywallView`の`dismissAfterPurchaseCompletionCallbacks`）ので、閉じるアニメーションと重ならないようにする
- オンボーディング中の課金は対象にしない。オンボーディングは`AppTabView`が出る前（`preLoggedIn`）に表示されるので、検知する場所を`AppTabView`にすれば自然に外れる
- C・D: ありがとうを受け取ったことを家事一覧のリスナーで検知してから、1〜2秒待って出す。起動直後に検知することが多い
- 同じタイミングでC・Dの両方を満たしたときは、Cを優先して1回だけ出す（Dは次の機会に回す）

#### 頻度制限

- 同じトリガーは1回しか出さない（A・C・Dでそれぞれ1回まで）
- どのトリガーでも、前回リクエストしてから**30日以内**は出さない
  - 制限中に条件を満たしても、そのトリガーは使い切らない。30日たった後の次の機会に出す
- OS側の制限（1年に最大3回）もかかる

#### Analytics

- 評価をリクエストしたときに`app_review`イベントを送る
  - パラメータ: `trigger`（`purchase` / `thanks_count` / `thanks_after_two_weeks`）
- `requestReview`はダイアログが実際に出たかどうかを返さないので、イベントは「表示した」ではなく「**リクエストした**」という意味になる
- `doc/analytics_events.md`に追記する

### 非機能要件 / 制約

- 判定ロジックはHometeDomainの値型（`AppReviewPolicy`）に置き、ユニットテストで網羅する（時刻は引数で渡す）
- リクエストを実行するのはView側の1か所だけなので、Storeは作らない。`AppTabView`で変化を検知して判定を呼び、`@Environment(\.requestReview)`を呼ぶ
- 端末への保存はUserDefaultsを使う（端末ごとの記録でよく、Firestoreには持たない）
- TestFlightでは評価ダイアログが出ない。動作確認はDebugビルドで行う

## 設計方針

### 1. 判定するモデル: `AppReviewPolicy`

`LocalPackage/Sources/HometeDomain/AppReview/AppReviewPolicy.swift`に値型として作る。端末に保存する記録（`AppReviewState`）を持ち、トリガーの判定と頻度制限を担当する。副作用（保存・Analytics・`requestReview`）は持たない。

```swift
public struct AppReviewPolicy: Equatable, Sendable {

    public private(set) var state: AppReviewState

    /// プランの変化からトリガーAを判定する
    /// - Note: 未取得（nil）からの変化は起動時の取得なので課金とみなさない
    public func purchaseTrigger(from oldValue: EntitlementInfo?, to newValue: EntitlementInfo?, now: Date) -> AppReviewTrigger?

    /// 家事一覧からありがとうを数え、トリガーC・Dを判定する
    public mutating func receiveThanks(in items: StoredAllHouseworkList, accountId: String, now: Date) -> AppReviewTrigger?

    /// リクエストしたことを記録する
    public mutating func markRequested(_ trigger: AppReviewTrigger, now: Date)
}
```

`AppReviewTrigger`はトリガーの種類を表すenum（`purchase` / `thanksCount` / `thanksAfterTwoWeeks`）。

### 2. ありがとうの数え方

FirestoreのデータはプランごとのFirestore上の保持期間やリスナーの取得範囲で減ることがあるので、毎回数え直さず、**端末に累計を持って増やしていく**。

- 「どこまで数えたか」を、ありがとうの`sentAt`の目印（`thanksCountedUntil`）で持つ
  - `sentAt`が目印より新しいありがとうだけを新しく受け取った分として数え、数えた中で一番新しい`sentAt`に目印を進める
  - `sentAt`はコメントを編集しても変わらないので（`HouseworkThanks`）、編集で二重に数えることはない。家事を完了し直すとありがとうは消えて付け直しになるので、その場合は新しく数える
- 初めて判定するときに、目印と使い始めた日を「今」で初期化する。これでアップデート前に届いていた分は数えない
- 家事のIDと送った人のIDの組をすべて保存する方法も考えた。ただ、リスナーが空の一覧を返したときなどに保存した組を整理する処理が必要になるので、目印の方式にした
- 送った人の端末の時計がずれていたり、オフラインで送ったありがとうが遅れて届いたりすると、数え漏れることがある。評価を出すきっかけを判定するだけなので、それでもよいとする

### 3. 保存先: `AppReviewStateClient`

`NotificationGuideStateClient`と同じ形で、プロトコルとpreviewValueを`HometeDomain/Dependencies/`に、UserDefaultsを使うliveValueを`AppRoot/Dependency/Impl/`に置く。

保存する内容（1つのCodable構造体`AppReviewState`にまとめる）:

| 項目 | 型 | 用途 |
|---|---|---|
| `startedAt` | `Date?` | 使い始めた日（D） |
| `thanksCountedUntil` | `Date?` | ありがとうをどこまで数えたか |
| `receivedThanksCount` | `Int` | 受け取ったありがとうの累計（C） |
| `requestedTriggers` | `Set<AppReviewTrigger>` | 出したトリガー |
| `lastRequestedAt` | `Date?` | 最後にリクエストした日時（30日の制限） |

### 4. View側の接続

`AppRoot`に`AppReviewRequestModifier`を新しく作り、`AppTabView`に付ける。`AppTabView`は家事一覧・プラン・ログイン情報をすべて持っているので、ここで検知する。

```swift
struct AppReviewRequestModifier: ViewModifier {

    @Environment(\.requestReview) var requestReview
    @Environment(\.appDependencies.appReviewStateClient) var appReviewStateClient
    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(\.loginContext) var loginContext
    @State var policy: AppReviewPolicy?

    let houseworkItems: StoredAllHouseworkList?

    func body(content: Content) -> some View {
        content
            .task { policy = .init(state: await appReviewStateClient.load()) }
            .onChange(of: subscriptionStore.entitlementInfo) { oldValue, newValue in /* トリガーA */ }
            .onChange(of: houseworkItems) { /* トリガーC・D */ }
    }
}
```

- トリガーが返ってきたら、少し待ってから`requestReview()`を呼ぶ。その後`markRequested`で記録を更新して保存し、`app_review`を送る
- `receiveThanks`は記録を更新するので、トリガーが返らなかったときも保存する
- 記録を読み込み終わる前の変化は判定しない（`policy`が`nil`の間は何もしない）

### 5. Analytics

- `AnalyticsEvent`に`appReview(trigger:)`を追加する。イベント名は`app_review`、パラメータは`trigger`
- 行動は「リクエストした」の1種類だけなので、`advertisement`イベントと同じく行動ごとのenumは作らない
- 送るのは`AppReviewRequestModifier`で`requestReview()`を呼んだ直後だけ

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/AppReview/AppReviewPolicy.swift` | トリガーの判定・頻度制限（値型） |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/AppReview/AppReviewTrigger.swift` | トリガーの種類 |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/AppReview/AppReviewState.swift` | 端末に保存する記録 |
| 新規Client | `LocalPackage/Sources/HometeDomain/Dependencies/AppReviewStateClient.swift` | 記録の読み書き（previewValue） |
| 新規Client実装 | `LocalPackage/Sources/AppRoot/Dependency/Impl/ImplAppReviewStateClient.swift` | UserDefaultsでの読み書き |
| 修正DI | `LocalPackage/Sources/AppRoot/Dependency/AppDependencies+liveValue.swift` | liveValueを登録 |
| 修正DI | `LocalPackage/Sources/HometeDomain/Dependencies/AppDependencies.swift` | `appReviewStateClient`を追加 |
| 修正Analytics | `LocalPackage/Sources/HometeDomain/AnalyticsLog/AnalyticsEvent.swift` | `appReview`を追加 |
| 修正AppRoot | `LocalPackage/Sources/AppRoot/AppTabView.swift` | `AppReviewRequestModifier`を付ける |
| 新規AppRoot | `LocalPackage/Sources/AppRoot/AppReview/AppReviewRequestModifier.swift` | 変化の検知・記録の保存・`requestReview`の呼び出し・Analytics |
| 新規テスト | `LocalPackage/Tests/HometeDomainTests/AppReview/AppReviewPolicyTest.swift` | 判定ロジックのテスト |
| 修正ドキュメント | `doc/analytics_events.md` | `app_review`イベントを追記 |
| 新規ADR | `doc/adr/0041-app-review-request-triggers.md` | トリガーと数え方の決定経緯 |

## タスク

### Phase 1: 設計確定

- [x] トリガーはA（課金）・C（ありがとう10回）・D（使い始めて14日以降のありがとう）
- [x] OS標準の`requestReview`をそのまま使う
- [x] 頻度制限は「各トリガー1回」+「前回から30日空ける」
- [x] Cは10回の1段階だけ
- [x] C・Dで数えるのはアップデート後に届いたありがとうだけ。使い始めた日もアップデート後に初めて起動した日
- [x] C・Dは検知してから1〜2秒待って出す
- [x] Storeは作らず、判定は値型`AppReviewPolicy`に置いて`AppTabView`で変化を検知する
- [x] トリガーAはペイウォールではなくプランの変化で検知する（オンボーディング中の課金は対象外）
- [x] Analyticsは`app_review`イベント + `trigger`パラメータ

### Phase 2: 実装

- [ ] `AppReviewTrigger` / `AppReviewState` / `AppReviewStateClient`（previewValue・liveValue）を追加し、`AppDependencies`に登録
- [ ] `AnalyticsEvent.appReview`を追加
- [ ] `AppReviewPolicy`を実装（トリガーA・C・Dの判定、頻度制限、記録の更新）
- [ ] `AppReviewPolicyTest`を追加
- [ ] `AppReviewRequestModifier`を実装し、`AppTabView`に付ける
- [ ] `doc/analytics_events.md`に`app_review`を追記
- [ ] ADR-0041を作成

### Phase 3: 検証

- [ ] `swift build` でビルド通過
- [ ] `swift-code-verification` スキルに沿って SwiftLint 通過
- [ ] ユニットテスト実行（追加分含む）通過
- [ ] スナップショットテスト（Prefire経由で自動生成）通過 / 必要なら参照画像を更新（画面の見た目は変わらない想定）
- [ ] Debugビルドで、課金後とありがとうを受け取った後に評価ダイアログが出ることを確認

### Phase 4: PR

- [ ] PR作成（`pr-create` スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/362
- 既存実装（参考）:
  - `LocalPackage/Sources/HometeDomain/Dependencies/NotificationGuideStateClient.swift`（端末に記録を持つClient）
  - `LocalPackage/Sources/HometeDomain/Subscription/SubscriptionStore.swift`（プランの判定）
  - `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkThanks.swift`（ありがとうの`sentAt`）
- Apple: [Requesting App Store reviews](https://developer.apple.com/documentation/storekit/requesting-app-store-reviews)
