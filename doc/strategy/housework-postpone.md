# 未完了の家事を別の日にまわす 実装方針

> 関連Issue: [#527 Feature: 未完了の家事を明日・別の日にまわせるようにする](https://github.com/stotic-dev/homete_iOS/issues/527)
> ブランチ: `feat/housework-postpone`（予定）
> テンプレートの仮想表示は [ADR-0003](../adr/0003-housework-template-virtual-view.md) / [ADR-0022](../adr/0022-monthly-housework-template-items.md) を参照。

## ステータス

- [x] 要件確定
- [ ] 設計確定（「Phase 1」の残課題を参照）
- [ ] 実装完了
- [ ] テスト追加完了
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
| 同じテンプレートの家事が**未完了**で出ている（仮想表示・登録済みどちらも） | **まとめる**: 移動先には増やさず、元の日から消すだけ。「明日の『お皿洗い』にまとめました」と伝える |
| 同じテンプレートの家事が完了・やらないになっている | 単発の家事として移す |
| 同じテンプレートの家事が出ない日（毎週月曜の家事を火曜へ等） | 単発の家事として移す |

**同じ名前の家事が移動先にあるとき**

- 「まとめる」に当たらない場合で、移動先に同じ名前の家事（状態は問わない）があるときは、確認のアラートを出す
  - 例: 「10/31には『洗濯』がすでにあります。まわしますか？」 → 「まわす」「キャンセル」
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
        destinationItems: [HouseworkItem],  // 移動先の日の家事（テンプレートを当てた後）
        now: Date,
        calendar: Calendar,
        storagePolicy: HouseworkStoragePolicy,
        idGenerator: () -> String
    ) -> Self
}
```

| まわす家事 | 移動先 | `writes` |
|---|---|---|
| 単発（`templateHouseworkItemId == nil`、必ず登録済み） | — | `[target.postponed(to:expiredAt:)]`（同じドキュメントの日付を書き換える） |
| テンプレート | 同じテンプレートの家事が未完了 | `[target.markedAsPostponed(to:)]`（`outcome = .merged`） |
| テンプレート | それ以外 | `[target.markedAsPostponed(to:), target.makePostponedCopy(...)]` |

- テンプレートの家事がまだ登録されていない（仮想表示）なら、元の日の記録は`updateCreatedAt(now)`を付けて新規作成する（`HouseworkListStore.remove`と同じ）
- 単発の家事を日付の書き換えで移すのは、IDを保てばメモ・作成日時・リスナーの同一性がそのまま引き継がれるため。単発の家事は元の日に記録を残す必要がない
- 移動先の日の家事は、テンプレートを当てた後の一覧（`HouseworkTemplateDay.applyTemplate`の結果）を渡す。仮想表示のテンプレートの家事と比べるため

### 3. 元の日に残す記録を画面に出さない

`postponedTo`付きの記録は`notTodo`なので、何もしないと元の日の「やらない」タブに出る。

- `HouseworkTemplateDay.applyTemplate`の結果から`postponedTo != nil`の家事を除く。テンプレートの重複判定（`registeredItems.contains { $0.templateHouseworkItemId == ... }`）には使うので、**判定の後で除く**
- `StoredAllHouseworkList`の段階では除かない（除くとテンプレートの家事が仮想表示で復活する）
- `applyTemplate`を通らずに保存済みの家事を並べている箇所（家事ボードの各タブ・`TodayHouseworkSummary`・Contributionの集計・App Intentの家事一覧・ふりかえり通知の件数）を実装時に洗い出し、出てしまう箇所で除く。`notTodo`なのでポイントの集計には元々入らない

### 4. Store（`HouseworkListStore.postpone`）

```swift
/// 未完了の家事を別の日へまわす
/// - Returns: まとめたかどうか（画面の文言に使う）
public func postpone(
    plan: HouseworkPostponePlan,
    cohabitantId: String,
    step: HouseworkAnalyticsStep
) async throws -> HouseworkPostponePlan.Outcome
```

- 計画は呼び出し側（Screen）で、リスナーで受け取った最新の記録とテンプレートから作る。確認のアラートを出すかどうかを、書き込む前に決めるため
- 書き込みは`insertOrUpdateItems(plan.writes, cohabitantId)`の1回だけ
- 画面を開いている間に同居人が完了にしていた場合は、最新の記録が未完了でなければ何もせず返す（`updateAndSave`と同じく、最新の記録で判定する）

### 5. クイックアクション（`HouseworkQuickAction`）

- ケース`postponeToNextDay`を足す。行き先はどちらも家事の日付の翌日で、「明日にまわす」「今日にまわす」の出し分けはView側（`HouseworkQuickAction+Presentation.swift`）で家事の日付から決める
- `actions(for:ownUserId:canAddHelper:)`に`now`・`calendar`を足し、未完了で、家事の日付が今日か昨日のときだけ`postponeToNextDay`を入れる。並びは`[.complete, .postponeToNextDay, .remove]`
- `actions(for state:)`（ホームの未完了一覧。今日の家事だけ）は`[.complete, .postponeToNextDay, .remove]`
- `isAvailableInBulk`は`false`
- メニューの区切り線は`HouseworkQuickActionMenuContent`で`.remove`の前に入れる
- アイコンは`arrow.turn.down.right`を第一候補にする（VRTで見て決める）

### 6. 家事詳細（`HouseworkDetailAction`）

- ケース`postpone`を足す（`isPrimary == false`）。未完了の家事のときの並びは`[.complete, .postpone, .remove]`
- タップでまわす日を選ぶハーフモーダルを出す
  - `HouseworkDatePickerView`を流用できるか先に確かめる。今のピッカーはボードの表示日を切り替えるためのもので、保存期間のPaywallへの導線を持ち、日付をタップするとすぐ決まる。「まわす日を選ぶ」というタイトル・今の日付を選べなくすること・保存期間の導線を出さないことを引数で切り替えられなければ、`HouseworkPostponeDatePickerView`（UIのみ）を新しく作る
  - 新しく作るなら画面として`AppScreen.housework_postpone_date_picker`を足し、`screen_view`を送る（`doc/analytics_events.md`の画面一覧も更新）
- まわしたら家事詳細をpopして家事ボードへ戻る

### 7. まわした家事のラベル

- 家事ボードの行（`HouseBoardListRow`など）と家事詳細の見出しの近くに、`postponedFrom`があれば「10/29から」を出す。日付の書式は`calendar`・`locale`に合わせる
- 表示するかどうかは`HouseworkBoardItem`に`postponedFrom`を通して、View側で決める。文言・アイコンはViewに置く（`ui-attributes-in-view.md`）

### 8. 操作のあとの伝え方

- まとめたとき: 「明日の『お皿洗い』にまとめました」
- 移したとき: 「明日にまわしました」/「今日にまわしました」/「11/2にまわしました」
- 既存のトースト（HometeUI）があればそれを使う。無ければ、まわした家事が画面から消えることで伝わるので、まとめたときだけ伝える形にする（実装時に確認）

### 9. Analytics

`HouseworkAnalyticsAction`に`postpone(step:isMerged:isSuccess:)`を足し、`housework`イベントの`action = postpone`で送る。`is_merged`パラメータで、まとめたかどうかを区別する（ADR-0009）。`doc/analytics_events.md`の`### housework`を更新する。

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 修正モデル | `LocalPackage/Sources/HometeModel/Cohabitant/Housework/HouseworkItem.swift` | `postponedFrom`・`postponedTo`、まわす操作、Codable |
| 修正モデル | `LocalPackage/Sources/HometeModel/Cohabitant/HouseworkTemplate/HouseworkTemplateDay.swift` | `applyTemplate`で元の日の記録を除く |
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkPostponePlan.swift` | 書き込む家事・まとめるか・同じ名前の家事の判定 |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkListStore.swift` | `postpone` |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/AnalyticsLog/HouseworkAnalyticsAction.swift` | `postpone` |
| 修正Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkQuickAction.swift` | `postponeToNextDay`と出す条件 |
| 修正Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkDetailAction.swift` | `postpone` |
| 修正Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkBoardItem.swift` | `postponedFrom`を通す |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/Components/HouseworkQuickAction+Presentation.swift` | 「明日にまわす」「今日にまわす」の文言・アイコン |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkBoardView/SubViews/HouseworkQuickActionMenuContent.swift` | 実行・区切り線・確認のアラート |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkDetailView/` | メニュー・ピッカーの表示・まわした後のpop・ラベル |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkBoardView/SubViews/`（行） | 「10/29から」のラベル |
| 新規View（必要なら） | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkPostponeDatePicker/` | まわす日を選ぶピッカー |
| 修正 | `LocalPackage/Sources/Features/HouseworkFeature/Localizable.xcstrings` | 文言と英訳 |
| 修正ドキュメント | `doc/analytics_events.md` | `postpone`・（必要なら）画面 |
| 新規ADR | `doc/adr/NNNN-housework-postpone-without-new-state.md` | 状態を増やさず、テンプレートの家事は元の日に隠した記録を残す方式にした判断 |

## タスク

### Phase 1: 設計確定

- [x] 元の日からは消し、移動先に「◯/◯から」のラベルを付ける
- [x] テンプレートの家事は、移動先の同じ家事が未完了ならまとめ、完了・やらないなら単発の家事として移す
- [x] クイックアクションは今日の家事に「明日にまわす」、昨日の家事に「今日にまわす」だけを出す
- [x] 家事詳細の「その他」メニューは「別の日にまわす…」（ピッカー）1つだけ
- [x] 一括操作には入れない
- [x] 対象は未完了だけ・移動先は今日から今日+7日・同じ名前の家事は確認・通知なし・無料
- [ ] [homete_backend](https://github.com/stotic-dev/homete_backend)のFirestoreルールが`Houseworks`のフィールドを列挙して制限していないか確かめる。制限していれば`postponedFrom`・`postponedTo`を許可するルールの変更を、アプリの審査提出より先にstg・prodへデプロイする
- [ ] `HouseworkDatePickerView`を流用するか、新しいピッカーを作るかを決める
- [ ] 既存のトーストの有無を確かめ、まわしたあとの伝え方を決める
- [ ] ADRを書く（番号は両リポジトリの最大番号+1）

### Phase 2: 実装

- [ ] `HouseworkItem`に`postponedFrom`・`postponedTo`とまわす操作を追加し、既存の`updateXxx`で引き継ぐ（テスト: Codable・引き継ぎ漏れ）
- [ ] `HouseworkPostponePlan`を追加（テスト: 単発・まとめる・完了済みの先・テンプレートが出ない日・未登録のテンプレートの家事・同じ名前の家事・月末をまたぐ日付）
- [ ] `applyTemplate`と、保存済みの家事を並べる箇所で元の日の記録を除く（テスト: 仮想表示が復活しないこと・やらないタブに出ないこと）
- [ ] `HouseworkListStore.postpone`とAnalyticsを追加（テスト: 書き込む家事・Analyticsのパラメータ・最新が未完了でないときに何もしないこと）
- [ ] `HouseworkQuickAction`に`postponeToNextDay`を追加し、今日・昨日の出し分け（テスト: 今日・昨日・一昨日・明日・日付をまたぐ直前の時刻）
- [ ] クイックアクションのメニューに表示・実行・確認のアラートを追加
- [ ] `HouseworkDetailAction`に`postpone`を追加し、ピッカーの表示・まわした後のpopを実装
- [ ] 家事ボードの行と家事詳細に「◯/◯から」のラベルを追加
- [ ] 文言と英訳を`Localizable.xcstrings`に追加
- [ ] Previewの追加・修正: `HouseworkQuickActionMenuContent`（今日・昨日・一昨日）、ラベル付きの行、家事詳細のメニュー、ピッカー
- [ ] `doc/analytics_events.md`を更新

### Phase 3: 検証

- [ ] `make build-affected`でビルド通過
- [ ] SwiftLint通過（`swift-code-verification`スキル）
- [ ] `make test-affected`でユニットテスト通過
- [ ] `make snapshot-affected`でVRT確認（参照画像の更新はCIに任せる）
- [ ] `make check-translations`通過
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
