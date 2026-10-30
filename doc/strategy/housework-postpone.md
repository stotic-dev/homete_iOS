# 未完了の家事を別の日にまわす 実装方針

> 関連Issue: [#527 Feature: 未完了の家事を明日・別の日にまわせるようにする](https://github.com/stotic-dev/homete_iOS/issues/527)
> ブランチ: `feat/housework-postpone`
> 設計の判断は [ADR-0064](../adr/0064-housework-postpone-without-new-state.md)、テンプレートの仮想表示は [ADR-0003](../adr/0003-housework-template-virtual-view.md) / [ADR-0022](../adr/0022-monthly-housework-template-items.md) を参照。

## ステータス

- [x] 要件確定
- [x] 設計確定
- [x] 実装完了
- [x] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

その日にできなかった未完了の家事を、別の日へ移す「まわす」操作を追加する。今は「やらない」にしてから翌日に登録し直す必要がある。
夜に「今日はもう無理」となった家事を明日へ、朝に「昨日やり残した」家事を今日へ、ワンタップで移せるようにする。

## 要件

### 機能要件

**家事ボードのクイックアクション（行の「…」メニュー・長押しメニュー）**

- 未完了の家事のうち、**今日の家事には「明日にまわす」、昨日の家事には「今日にまわす」**を出す。どちらも家事の日付の翌日へ移す
- 一昨日より前の家事と、明日以降の家事には出さない（家事詳細のピッカーからまわせる）
- メニューの並びは「完了にする」「明日にまわす / 今日にまわす」、区切り線、「やらない」（destructive）
- ホームの「未完了の家事」一覧（今日の家事だけ）にも同じく「明日にまわす」を出す
- 複数選択の一括操作には入れない（`isAvailableInBulk == false`）

**家事詳細の「その他」メニュー**

- 未完了の家事に「別の日にまわす…」を1つだけ出す（「明日にまわす」は並べない）
- タップすると日付ピッカーをハーフモーダルで出し、まわす日を選ぶ
  - 選べるのは今日から、家事ボードで選べる最も先の日（今日+7日、`HouseworkDateList.forwardSelectableOffset`）まで。家事の今の日付は選べない
- まわしたら家事詳細を閉じて家事ボードへ戻る（家事はもうその日に無いため）

**まわした家事の見え方**

- 元の日からは消し、移動先では普通の未完了の家事として表示する
- 移動先の行と家事詳細に「10/29から」のように、まわす前の日付のラベルを出す
- 2回まわしたときは、直前の日付を出す（最初の日付を出し続けると、先延ばしを責めるように見えるため）
- 同居人への通知は送らない
- 無料プランでも使える

**テンプレート（毎週・毎月）の家事**

| 移動先の日の状態 | 結果 |
|---|---|
| 同じテンプレートの家事が**未完了**で出ている（仮想表示・登録済みどちらも） | **まとめる**: 移動先には増やさず、元の日から消すだけ。まわす前に「1/11にも『お皿洗い』があるので、その日の分にまとめます。」と確認のアラートで伝える |
| 同じテンプレートの家事が完了・やらないになっている | 単発の家事として移す |
| 同じテンプレートの家事が出ない日（毎週月曜の家事を火曜へ等） | 単発の家事として移す |

**同じ名前の家事が移動先にあるとき**

- 「まとめる」に当たらない場合で、移動先に同じ名前の家事（状態は問わない）があるときは、確認のアラートを出す
  - 例: 「このまままわしますか？」「10/31には『洗濯』がすでにあります。」 → 「まわす」「キャンセル」
- 移動なので、登録画面と違ってブロックはしない

### 非機能要件 / 制約

- `HouseworkState`は増やさない（Contribution・今日のふりかえり・ポイントの集計に影響を広げないため）
- 書き込みは1回の`WriteBatch`（`HouseworkClient.insertOrUpdateItems`）にまとめ、元の日だけ消えて移動先に無い、という中途半端な状態を作らない
- 旧バージョンのアプリは新しいフィールドを読まない。`setData(merge: false)`で上書きされるとフィールドが消える（ADR-0023と同じ）。影響はラベルが消える程度で、家事そのものは壊れない
- 移動先の判定（まとめるか・単発にするか・同じ名前の家事があるか）はドメイン層の値型に置き、`Calendar`を引数で受け取ってユニットテストする
- 文言は「まわす」で統一し、英訳も入れる（`make check-translations`）

## 設計方針

### 1. ドメインモデル（`HouseworkItem`）

`HometeModel/Cohabitant/Housework/HouseworkItem.swift`に2つのフィールドを足す。どちらも任意で、`decodeIfPresent` / `encodeIfPresent`にする。

```swift
/// まわす前の日付。移動先の家事に付け、「10/29から」のラベルに使う
public let postponedFrom: HouseworkIndexedDate?
/// まわした先の日付。テンプレートの家事を別の日へまわしたときに、元の日に残す記録に付ける
///
/// テンプレートの家事は仮想表示（ADR-0003）なので、元の日に記録を残さないとテンプレートからまた出てしまう。
/// この記録は`notTodo`にして、画面には出さない。
public let postponedTo: HouseworkIndexedDate?
```

足す操作:

```swift
/// 別の日へ移す（登録済みの単発の家事）。IDは変えずに、日付・保持期限・まわす前の日付だけを変える
func postponed(to destination: HouseworkIndexedDate, expiredAt: Date) -> Self
/// テンプレートの家事を別の日へまわしたときに、元の日に残す記録にする（`notTodo` + `postponedTo`）
func markedAsPostponed(to destination: HouseworkIndexedDate) -> Self
/// 移動先に作る単発の家事。テンプレートIDは引き継がない（`makeRedone`と同じ考え方）。メモは引き継ぐ
func makePostponedCopy(id: String, to destination: HouseworkIndexedDate, expiredAt: Date, at now: Date) -> Self
```

既存の`updateXxx`系がすべての項目を詰め直しているので、2つのフィールドも漏れなく引き継ぐ（引き継ぎ漏れをテストで確かめる）。

### 2. まわし方の判定（`HouseworkPostponePlan`）

`HometeDomain/Cohabitant/Housework/HouseworkPostponePlan.swift`に、書き込む家事を決める値型を置く。Storeから呼び、Viewは結果（まとめたか・確認が要るか）だけを使う。

```swift
public struct HouseworkPostponePlan: Equatable, Sendable {

    public enum Outcome: Equatable, Sendable {
        /// 単発の家事として移す
        case moved
        /// 移動先の同じテンプレートの家事にまとめる
        case merged
    }

    /// 書き込む家事（元の日の記録と、移動先の家事）
    public let writes: [HouseworkItem]
    public let outcome: Outcome
    /// 移動先にある同じ名前の家事（確認のアラートに使う。まとめるときは`nil`）
    public let conflictingTitle: String?

    public static func make(
        target: HouseworkItem,
        isRegistered: Bool,
        destination: Date,
        storedItems: StoredAllHouseworkList,         // 登録済みの家事（移動先の日の家事を探す）
        templateContext: HouseworkTemplateContext,  // 移動先の日にテンプレートから出る家事を探す
        now: Date,
        calendar: Calendar,
        storagePolicy: HouseworkStoragePolicy,
        newItemId: String  // 移動先に単発の家事を作るときのID
    ) -> Self
}
```

| まわす家事 | 移動先 | `writes` |
|---|---|---|
| 単発（`templateHouseworkItemId == nil`、必ず登録済み） | — | `[target.postponed(to: metaData)]`（同じドキュメントの日付を書き換える） |
| テンプレート | 同じテンプレートの家事が未完了 | `[target.markedAsPostponed(to:)]`（`outcome = .merged`） |
| テンプレート | それ以外 | `[target.markedAsPostponed(to:), target.makePostponedCopy(...)]` |

- テンプレートの家事がまだ登録されていない（仮想表示）なら、元の日の記録は`updateCreatedAt(now)`を付けて新規作成する（`HouseworkListStore.remove`と同じ）
- 単発の家事を日付の書き換えで移すのは、IDを保てばメモ・作成日時・リスナーの同一性がそのまま引き継がれるため。単発の家事は元の日に記録を残す必要がない
- 移動先の日の家事は、`make`の中で登録済みの家事にテンプレートを当てて求める（`HouseworkTemplateDay.applyTemplate`）。仮想表示のテンプレートの家事と比べるため

### 3. 元の日に残す記録を画面に出さない

`postponedTo`付きの記録は`notTodo`なので、何もしないと元の日の「やらない」タブに出る。

- `HouseworkTemplateDay.applyTemplate`の結果から`postponedTo != nil`の家事を除く。テンプレートの重複判定（`registeredItems.contains { $0.templateHouseworkItemId == ... }`）には使うので、**判定の後で除く**
- `StoredAllHouseworkList`の段階では除かない（除くとテンプレートの家事が仮想表示で復活する）
- `applyTemplate`を通らずに保存済みの家事を並べている箇所（家事ボードの各タブ・`TodayHouseworkSummary`・Contributionの集計・App Intentの家事一覧・ふりかえり通知の件数）を実装時に洗い出し、出てしまう箇所で除く。`notTodo`なのでポイントの集計には元々入らない

### 4. Store（`HouseworkListStore.postpone`）

```swift
/// 未完了の家事を別の日へまわす
/// - Returns: まわした結果。最新の記録が未完了でなく、まわさなかったときは`nil`
public func postpone(
    target: HouseworkItem,
    isRegistered: Bool,
    to destination: Date,
    templateContext: HouseworkTemplateContext,
    storagePolicy: HouseworkStoragePolicy,
    cohabitantId: String,
    step: HouseworkAnalyticsStep
) async throws -> HouseworkPostponePlan.Outcome?

/// 書き込まずに計画だけを返す（確認のアラートを出すかどうかを決めるのに使う）
public func postponePlan(...) -> HouseworkPostponePlan
```

- 確認のアラートを出すかどうかは`postponePlan`で書き込む前に決める。了承されたら`postpone`が最新の記録で計画を作り直して書き込む
- 書き込みは`insertOrUpdateItems(plan.writes, cohabitantId)`の1回だけ
- 画面を開いている間に同居人が完了にしていた場合は、最新の記録が未完了でなければ何もせず返す（`updateAndSave`と同じく、最新の記録で判定する）

### 5. クイックアクション（`HouseworkQuickAction`）

- ケース`postponeToTomorrow`（「明日にまわす」）と`postponeToToday`（「今日にまわす」）を足す。行き先はどちらも家事の日付の翌日。文言・アイコンを状態ごとに分けるため、ケースを2つにする
- 1件の家事のメニューには`menuActions(for:ownUserId:canAddHelper:now:calendar:)`を使う。`actions(for:ownUserId:canAddHelper:)`に、家事の日付が今日なら`postponeToTomorrow`、昨日なら`postponeToToday`を「やらない」の前に足す。並びは`[.complete, .postponeToTomorrow, .remove]`
- `actions(for:ownUserId:canAddHelper:)`には入れない。複数選択の「一緒に選べるか」の判定に使っているため、入れると今日と昨日の家事を一緒に選べなくなる
- `isAvailableInBulk`は`false`
- メニューの区切り線は`HouseworkQuickActionMenuContent`で`.remove`の前に入れる
- アイコンは`arrow.turn.down.right`を第一候補にする（VRTで見て決める）

### 6. 家事詳細（`HouseworkDetailAction`）

- ケース`postpone`を足す（`isPrimary == false`）。未完了の家事のときの並びは`[.complete, .postpone, .remove]`
- タップでまわす日を選ぶハーフモーダルを出す
  - `HouseworkDatePickerView`は保存期間のPaywallへの導線を持つボード専用のピッカーなので流用せず、`HouseworkPostponeDatePickerView`（UIのみ）を新しく作る。選べる範囲と最初に選んでおく日は`HouseworkPostponeDateRange`（Feature の`Model/`）で決め、家事の今の日付を選んでいる間は確定ボタンを押せなくする
  - 画面として`AppScreen.houseworkPostponeDatePicker`（`housework_postpone_date_picker`）を足し、`screen_view`を送る（`doc/analytics_events.md`の画面一覧も更新）
- まわしたら家事詳細をpopして家事ボードへ戻る

### 7. まわした家事のラベル

- 家事ボードの行（`HouseBoardListRow`など）と家事詳細の見出しの近くに、`postponedFrom`があれば「10/29から」を出す。日付の書式は`calendar`・`locale`に合わせる
- 表示するかどうかは`HouseworkBoardItem`に`postponedFrom`を通して、View側で決める。文言・アイコンはViewに置く（`ui-attributes-in-view.md`）

### 8. 操作のあとの伝え方

- HometeUIにトーストが無いため、まわした後には何も出さない。まわした家事が画面から消え、移動先ではラベルが付くことで伝わる
- まとめるときと同じ名前の家事があるときは、まわす**前**に確認のアラート（`houseworkPostponeConfirmation`）で伝える
  - `.contextMenu`の中からはアラートを出せないので、メニュー（`HouseworkQuickActionMenuContent`）は確かめる内容を`onRequestPostponeConfirmation`で呼び出し元へ伝え、家事ボード・ホームの今日の家事・未完了の家事・家事詳細の各画面にModifierを付ける

### 9. Analytics

`HouseworkAnalyticsAction`に`postpone(step:outcome:isSuccess:)`を足し、`housework`イベントの`action = postpone`で送る。単発の家事として移したか、まとめたかは`kind`（`moved` / `merged`）で区別する。カスタムディメンションを増やさないため、`encouragement_comment`の`kind`と同じキーを使い回す（ADR-0009、`doc/analytics_events.md`の命名ポリシー5）。`doc/analytics_events.md`の`### housework`を更新する。

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 修正モデル | `LocalPackage/Sources/HometeModel/Cohabitant/Housework/HouseworkItem.swift` | `postponedFrom`・`postponedTo`、まわす操作、Codable |
| 修正モデル | `LocalPackage/Sources/HometeModel/Cohabitant/HouseworkTemplate/HouseworkTemplateDay.swift` | `applyTemplate`で元の日の記録を除く |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkPostponePlan.swift` | 書き込む家事・まとめるか・同じ名前の家事の判定 |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkListStore.swift` | `postpone` |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/AnalyticsLog/HouseworkAnalyticsAction.swift` | `postpone` |
| 修正Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkQuickAction.swift` | `postponeToTomorrow`・`postponeToToday`と出す条件 |
| 修正Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkDetailAction.swift` | `postpone` |
| 修正Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkBoardItem.swift` | `postponedFrom`を通す |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/Components/HouseworkQuickAction+Presentation.swift` | 「明日にまわす」「今日にまわす」の文言・アイコン |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkBoardView/SubViews/HouseworkQuickActionMenuContent.swift` | 実行・区切り線・確認のアラート |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkDetailView/` | メニュー・ピッカーの表示・まわした後のpop・ラベル |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkBoardView/SubViews/`（行） | 「10/29から」のラベル |
| 新規View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkPostponeDatePicker/HouseworkPostponeDatePickerView.swift` | まわす日を選ぶピッカー |
| 新規Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkPostponeDateRange.swift` | ピッカーで選べる範囲・最初に選んでおく日 |
| 新規Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkPostponeConfirmation.swift`・`HouseworkListStore+Postpone.swift` | 確かめる内容と、確かめてからまわす流れ |
| 新規Component | `LocalPackage/Sources/Features/HouseworkFeature/Components/HouseworkPostponeConfirmationAlert.swift` | 確認のアラートを出してまわすModifier |
| 修正 | `LocalPackage/Sources/Features/HouseworkFeature/Localizable.xcstrings` | 文言と英訳 |
| 修正ドキュメント | `doc/analytics_events.md` | `postpone`・（必要なら）画面 |
| 新規ADR | `doc/adr/0064-housework-postpone-without-new-state.md` | 状態を増やさず、テンプレートの家事は元の日に隠した記録を残す方式にした判断 |

## タスク

### Phase 1: 設計確定

- [x] 元の日からは消し、移動先に「◯/◯から」のラベルを付ける
- [x] テンプレートの家事は、移動先の同じ家事が未完了ならまとめ、完了・やらないなら単発の家事として移す
- [x] クイックアクションは今日の家事に「明日にまわす」、昨日の家事に「今日にまわす」だけを出す
- [x] 家事詳細の「その他」メニューは「別の日にまわす…」（ピッカー）1つだけ
- [x] 一括操作には入れない
- [x] 対象は未完了だけ・移動先は今日から今日+7日・同じ名前の家事は確認・通知なし・無料
- [x] [homete_backend](https://github.com/stotic-dev/homete_backend)のFirestoreルールが`Houseworks`のフィールドを列挙して制限していないか確かめる。制限していれば`postponedFrom`・`postponedTo`を許可するルールの変更を、アプリの審査提出より先にstg・prodへデプロイする（→ 制限していないので変更不要）
- [x] `HouseworkDatePickerView`を流用するか、新しいピッカーを作るかを決める
- [x] 既存のトーストの有無を確かめ、まわしたあとの伝え方を決める
- [x] ADRを書く（番号は両リポジトリの最大番号+1）

### Phase 2: 実装

- [x] `HouseworkItem`に`postponedFrom`・`postponedTo`とまわす操作を追加し、既存の`updateXxx`で引き継ぐ（テスト: Codable・引き継ぎ漏れ）
- [x] `HouseworkPostponePlan`を追加（テスト: 単発・まとめる・完了済みの先・テンプレートが出ない日・未登録のテンプレートの家事・同じ名前の家事）
- [x] `applyTemplate`と、保存済みの家事を並べる箇所で元の日の記録を除く（テスト: 仮想表示が復活しないこと・やらないタブに出ないこと）
- [x] `HouseworkListStore.postpone`とAnalyticsを追加（テスト: 書き込む家事・Analyticsのパラメータ・最新が未完了でないときに何もしないこと）
- [x] `HouseworkQuickAction`に`postponeToTomorrow`・`postponeToToday`を追加し、今日・昨日の出し分け（テスト: 今日・昨日・一昨日・明日・日付をまたぐ直前の時刻）
- [x] クイックアクションのメニューに表示・実行・確認のアラートを追加
- [x] `HouseworkDetailAction`に`postpone`を追加し、ピッカーの表示・まわした後のpopを実装
- [x] 家事ボードの行と家事詳細に「◯/◯から」のラベルを追加
- [x] 文言と英訳を`Localizable.xcstrings`に追加
- [x] Previewの追加・修正: `HouseworkQuickActionMenuContent`（今日・昨日・一昨日）、ラベル付きの行、家事詳細のメニュー、ピッカー
- [x] `doc/analytics_events.md`を更新

### Phase 3: 検証

- [ ] `make build-affected`でビルド通過
- [ ] SwiftLint通過（`swift-code-verification`スキル）
- [ ] `make test-affected`でユニットテスト通過
- [ ] `make snapshot-affected`でVRT確認（参照画像の更新はCIに任せる）
- [x] `make check-translations`通過
- [ ] シミュレータで確認（`simulator-e2e-check`）: 今日→明日、昨日→今日、毎日の家事をまとめる、詳細のピッカーで3日後へ

### Phase 4: PR

- [ ] PR作成（`pr-create`スキル使用）。Firestoreルールの変更が要る場合は、デプロイの順番をPRの説明に書く
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/527
- 既存実装（参考）:
  - `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkListStore.swift`（`remove`の未登録の家事の扱い、`redo`、一括操作の`bulkUpdatedItems`）
  - `LocalPackage/Sources/HometeModel/Cohabitant/HouseworkTemplate/HouseworkTemplateDay.swift`（`applyTemplate`）
  - `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkQuickAction.swift`
  - `LocalPackage/Sources/Features/HouseworkFeature/HouseworkDatePicker/HouseworkDatePickerView.swift`
  - `doc/strategy/housework-repeat-option.md`（テンプレートの仮想表示とFirestoreルールのデプロイ順）
