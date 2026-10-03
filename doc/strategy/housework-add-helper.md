# 完了後の家事に手伝った人を追加 実装方針

> 関連Issue: [#351 Feature: 完了後の家事に「手伝った人」を追加できるようにする](https://github.com/stotic-dev/homete_iOS/issues/351)
> ブランチ: `feat/housework-add-helper`
> 担当者の複数化とポイント配分のデータモデル: [ADR-0023](../adr/0023-housework-multiple-executors-with-allocated-points.md)、頑張り度とポイントの関係: [ADR-0024](../adr/0024-housework-effort-level-as-separate-field.md)

## ステータス

- [x] 要件確定
- [x] 設計確定
- [x] 実装完了
- [x] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

完了にした後で「実は別の人にも手伝ってもらっていた」と分かったときに、完了済みの家事へ担当者を足せるようにする。

いまは完了時にしか担当者を選べないため、回避策は「未完了に戻して選び直す」（完了日時・ありがとう・コメントが消える）か「もう一度やった」で別の家事として積む（二重計上になる）しかない。手伝った人の貢献をポイントに反映できるようにして、同居人間の感謝・公平感を保つのが目的。

## 要件

### 機能要件

#### 導線

1. 家事詳細のアクションから「手伝った人を追加」を選ぶと、担当者を選ぶハーフモーダルを開く
2. アクションは画面下のボタンではなく、**ナビゲーションバー右側**に出す（下記「アクションの置き場所」）。「手伝った人を追加」は「その他」のメニューに入り、並び順は「もう一度やった」「未完了に戻す」より前。感謝と並ぶ positive な操作なので取り消し系より前に置く
3. **追加できるメンバーがいないときはメニューに出さない**。該当するのは次のどちらか
   - 同居人グループのメンバーが自分だけ（足せる相手がいない）
   - 人数の上限（`HouseworkExecutorAllocation.maxExecutorCount`）に既に達している
4. 家事ボードのクイックアクション（長押しメニュー）・複数選択の一括操作には入れない。1件ずつ配分を決める操作なので、`redo`と同じく一括の対象外とする

#### 担当者の選択と配分

5. ハーフモーダルの中身は「担当者」のチェックリストと「配分を調整する」だけ。頑張り度は変えないので出さない
6. **既存の担当者は選択済みで、外せない**。チェックを無効にして、未選択のメンバーを足すことだけできる
   - 誤って完了者を消すと完了記録の意味が変わるため。外したい場合は「未完了に戻す」で選び直す
7. **シートを開いた時点の割合は、保存済みの%をそのまま表示する**。開いただけ・保存しただけで配分が変わらないようにする
8. 人を足した時点で、完了時と同じく全員を**均等割りにし直す**。既存の%は保持しない（追加者の割合の決め方が一意でないため）
9. 「配分を調整する」は完了時と同じ挙動（2人のときは連動、3人以上は合計100%になるまで確定できない、0ptの担当者は許さない）
10. **家事の合計ポイント（`earnedPoint`）は変えない**。追加後の担当者でその合計を配り直す
11. 頑張り度・完了日時・ありがとう・コメント・作成日時は変えない

#### 権限

12. 同居人グループの全メンバーが操作できる。完了時の「代わりに記録」と同じ考え方

#### 保存と集計

13. `executors`を更新して保存する。`executorId`（旧アプリ向けの1人目）は既存のエンコード仕様どおり1人目の担当者が書かれる
14. 貢献度（`HouseworkContribution`）とホームの今日のサマリー（`TodayHouseworkSummary`）は`executors[].point`を集計しているため、追加後の配分がそのまま反映される。集計コードの変更は不要（テストで確認する）
15. 「ありがとう」は`isThankable`が「担当者に自分以外がいるか」で判定しているため、追加によって送れる対象が増える。既存のありがとうの記録はそのまま維持する

#### 通知

16. この操作では同居人へプッシュ通知を送らない。家事のステータスに関わる通知はふりかえり通知だけに絞る方針（ADR-0021）と、追加のたびに通知すると煽りになりやすいため
17. 追加された人が気付ける手段が必要になったら、追加された人にだけ送る通知を別Issueで検討する

#### Analytics

18. `housework`イベントの`action`に`add_helper`を追加する（ADR-0009のとおり、イベント名を増やさずパラメータで区別する）
19. ハーフモーダルは独立した画面として`screen_view`を送る（`housework_add_helper`）

### 非機能要件 / 制約

- 新しいフィールドは作らず、既存の`executors`に足す。手伝った人を別フィールドで持つと集計・表示・旧アプリ互換の実装が増えるだけでメリットがない
- 配分のロジック（`HouseworkExecutorAllocation`）とUI（`HouseworkExecutorSelectionContent` / `HouseworkExecutorAllocationContent`）は既存のものを再利用する
- Firestoreルール・Cloud Functionsは変更しない（Houseworksのフィールドを検証していない）
- 配分の計算はドメイン層の値型に閉じ、ユニットテストで固定する

## 設計方針

### 1. `HouseworkExecutorAllocation`に「外せない担当者」を足す

`LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkExecutorAllocation.swift`（修正）

完了時の配分と、完了後に手伝った人を足すときの配分は、次の2点だけが違う。

| | 完了にするとき | 手伝った人を追加するとき |
|---|---|---|
| 配分するポイント | `effort.boostedPoint(basePoint)` | 保存済みの`earnedPoint`をそのまま |
| 既存の担当者 | なし（自分だけ初期選択） | 選択済み・**外せない** |

これを表すために、`lockedIds`（外せない担当者）と、上乗せ後のポイントを直接受け取るファクトリを足す。

```swift
/// 外せない担当者のユーザーID（完了済みの家事に担当者を足すときの、既存の担当者）
public let lockedIds: [String]

/// 完了済みの家事に担当者を足すときの配分を作る
///
/// 家事の合計ポイントは変えずに配り直すため、配分の対象は上乗せ後のポイント（`HouseworkItem.earnedPoint`）。
/// 頑張り度は変えないので「ふつう」を指定して上乗せを無効にする。
/// 既存の担当者は保存済みの割合のまま並べ、人を足したときに均等割りへ戻す。
public static func forAddingExecutors(
    memberIds: [String],
    executors: [HouseworkExecutor],
    earnedPoint: Int
) -> Self
```

- `canToggle(_:)`は`lockedIds`に含まれる担当者を`false`にする。`toggle(_:)`も同じ条件で何もしない
- 配分の対象ポイントは、`effort`に`.normal`（上乗せ率100%）を渡し`basePoint`に`earnedPoint`を入れることで表す。`HouseworkEffort.normal.boostedPoint(x) == x`なので`totalPoint`は`earnedPoint`のままになり、人数の上限（`maxExecutorCount`）も合計ポイントを基準に決まる
- 既存の`init(memberIds:selectedIds:basePoint:effort:)`は`lockedIds`を空にするだけで、完了時の挙動は変わらない
- `entries`の初期値には保存済みの%**と並び順**を使う。ポイントへの換算は端数の行き先が並び順で決まるため、`memberIds`順（自分が先頭）に並べ替えると、同じ家事でも見ている人によって1ptの行き先が入れ替わってしまう（保存済みの配分を再現できず、開いて保存しただけで配分が変わる）。セッターに触れるため、ファクトリは`entries`と同一ファイル内に置く
- **メンバー一覧に居ない担当者**（アカウントを削除した同居人。`deleteUserData`はグループの`members`からは消すが、家事の`executors`には残る）がいる家事は、`canAddExecutor`を`false`にして導線を出さない。足すと均等割りをやり直す際に、その人の配分が黙って残りのメンバーへ移ってしまうため

### 2. `HouseworkItem.updateExecutors(_:)`を足す

`LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkItem.swift`（修正）

```swift
/// 完了済みの家事の担当者を入れ替える（手伝った人の追加）
///
/// 完了日時・頑張り度・ありがとう・作成日時は変えず、担当者とポイントの配分だけを更新する。
/// 完了していない家事は担当者を持たないため、そのまま返す。
public func updateExecutors(_ executors: [HouseworkExecutor]) -> Self
```

- `state == .completed`でなければ`self`を返す。画面を開いている間に同居人が未完了へ戻した場合に、担当者だけが付いた未完了の家事を作らないため
- `updateCompleted`と同じく、担当者のポイントの合計が`earnedPoint`と一致することを`assert`で守る

### 3. `HouseworkListStore.addHelpers`を足す

`LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkListStore.swift`（修正）

```swift
public func addHelpers(
    target: HouseworkItem,
    executors: [HouseworkExecutor],
    cohabitantId: String,
    step: HouseworkAnalyticsStep
) async throws
```

`updateAndSave`でリスナーが受け取った最新の家事に`updateExecutors`を適用して保存し、成否をAnalyticsに送る。通知は送らない（要件16）。

### 4. Analytics

`LocalPackage/Sources/HometeDomain/AnalyticsLog/HouseworkAnalyticsAction.swift`（修正）

```swift
/// 完了した家事に手伝った人を追加した
case addHelper(step: HouseworkAnalyticsStep, isSuccess: Bool)
```

`action`は`add_helper`。`step`は`detail`のみ（導線が家事詳細だけのため）。`executor_type`・`effort`・`source`は付けない。

`LocalPackage/Sources/HometeDomain/AnalyticsLog/AppScreen.swift`（修正）

```swift
/// 完了した家事に手伝った人を追加する画面（担当者とポイントの配分を入力するハーフモーダル）
case houseworkAddHelper = "housework_add_helper"
```

[doc/analytics_events.md](../analytics_events.md)の`housework`の`action`一覧・送信タイミングの表と、`screen_view`の画面一覧の表に行を足す。

### 5. ハーフモーダル`HouseworkAddHelperSheet`

`LocalPackage/Sources/Features/HouseworkFeature/HouseworkAddHelper/HouseworkAddHelperSheet.swift`（新規）

`HouseworkCompleteSheet`と同じ構成（Environmentから値を取る薄い`Sheet` + `#Preview`を持つ`View`）にする。

- `HouseworkAddHelperSheet`: `\.cohabitantMembers`・`\.loginContext.account`を取り出して`HouseworkAddHelperView`に渡すだけ
- `HouseworkAddHelperView`: `allocation`を`@State`で持ち、担当者のチェックリストと「配分を調整する」を並べる。ナビゲーションバー右のチェックアイコンで保存して`dismiss()`
- 既存担当者が外せないことは、`HouseworkExecutorSelectionContent.Row`に`isLocked`を足して表す。`isEnabled: false`の流用だと不透明度が落ちて「対象外のメンバー」に見えるため、ロック時はタップだけ不可にして薄くしない
- **保存できるのは、配分が確定できて、かつ保存済みの担当者から変わっているときだけ**にする。開いて保存しただけで書き込みと`add_helper`イベントが発生すると、「後から手伝った人を足した」件数を数えられなくなる
- 文言は「この家事を手伝ってくれた人を選ぶと、ポイントを分け合えます。」「もともとの担当者は外せません。」をキャプションで添える

### 6. アクションの置き場所と表示判断

`LocalPackage/Sources/Features/HouseworkFeature/HouseworkDetailView/SubViews/HouseworkDetailActionContent.swift`（修正）

「手伝った人を追加」で4つ目になり、画面下に縦に並ぶボタンが読みづらくなったため、アクションの置き場所自体を見直した。ナビゲーションバー右側に、その状態で一番よく使う操作（未完了なら「完了にする」、完了済みならありがとう系）を単独のアイコンボタンとして出し、残りは「その他」（`ellipsis`）のメニューに入れる。ステータスを変える操作と「やらない」は誤ってタップしても取り返しがつくように単独では出さず、それまで単独のゴミ箱アイコンだった「やらない」もメニューへ移した。

どのアクションを出すか・どれを単独で出すかは`Features/HouseworkFeature/Model/HouseworkDetailAction`に切り出してユニットテストで固定する。見せ方（文言・SF Symbol・`ButtonRole`）は`HouseworkQuickAction`と同じく`Components/`の拡張に置く（[ui-attributes-in-view](../../.claude/rules/ui-attributes-in-view.md)）。

判断は`cohabitantStore.members`を持つ`HouseworkDetailView`側の算出プロパティに置き、`HouseworkDetailActionContent`には結果だけを渡す（[presentation-logic-placement](../../.claude/rules/presentation-logic-placement.md)）。`HouseworkDetailActionContent`は`SubViews/`の末端コンポーネントなので、メンバー一覧から表示内容を導出させない。ハーフモーダルの提示とドメイン操作も`HouseworkDetailView`側に持たせる。

```swift
// HouseworkDetailView
var canAddHelper: Bool  // 完了済みで、HouseworkExecutorAllocation.canAddExecutorがtrueのとき
// HouseworkDetailActionContent
let canAddHelper: Bool
```

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 修正ドメイン | `HometeDomain/Cohabitant/Housework/HouseworkExecutorAllocation.swift` | `lockedIds`と`forAddingExecutors`を追加 |
| 修正ドメイン | `HometeDomain/Cohabitant/Housework/HouseworkItem.swift` | `updateExecutors(_:)`を追加 |
| 修正Store | `HometeDomain/Cohabitant/Housework/HouseworkListStore.swift` | `addHelpers`を追加 |
| 修正Analytics | `HometeDomain/AnalyticsLog/HouseworkAnalyticsAction.swift` | `addHelper`ケースを追加 |
| 修正Analytics | `HometeDomain/AnalyticsLog/AppScreen.swift` | `houseworkAddHelper`ケースを追加 |
| 新規View | `Features/HouseworkFeature/HouseworkAddHelper/HouseworkAddHelperSheet.swift` | 手伝った人を追加するハーフモーダル |
| 修正View | `Features/HouseworkFeature/HouseworkDetailView/SubViews/HouseworkDetailActionContent.swift` | 画面下のボタン群をナビゲーションバーのアイコンボタンと「その他」メニューに置き換え |
| 新規View | `Features/HouseworkFeature/HouseworkDetailView/SubViews/HouseworkDetailActionMenuContent.swift` | 「その他」メニューの中身 |
| 新規Model | `Features/HouseworkFeature/Model/HouseworkDetailAction.swift` | 詳細で行えるアクションと出し分け |
| 新規View | `Features/HouseworkFeature/Components/HouseworkDetailAction+Presentation.swift` | アクションの文言・アイコン・ロール |
| 修正View | `Features/HouseworkFeature/HouseworkDetailView/HouseworkDetailView.swift` | アクションの算出、ツールバー、シートの提示とドメイン操作 |
| 修正共通UI | `HometeUI/Components/Navigation/` | メニューを開くアイコンボタンと、画面固有アイコンを渡せるラベル |
| 修正ドキュメント | `doc/analytics_events.md` | `housework`の`action`と`screen_view`の表を更新 |
| 新規テスト | `LocalPackage/Tests/HometeDomainTests/Housework/...` | 配分・ドメイン更新・Store・貢献度集計 |

## タスク

### Phase 1: 設計確定

- [x] 既存の担当者を外せるか → 外せない（`lockedIds`で表す）
- [x] シートを開いた時点の割合 → 保存済みの%のまま。人を足したら均等割り
- [x] 追加できるメンバーがいないときのボタン → 非表示
- [x] 通知 → 送らない
- [x] 再配分の対象ポイント → 保存済みの`earnedPoint`（頑張り度から計算し直さない）

### Phase 2: 実装

- [x] `HouseworkExecutorAllocation`に`lockedIds`・`forAddingExecutors`を追加
- [x] `HouseworkItem.updateExecutors(_:)`を追加
- [x] `HouseworkListStore.addHelpers`を追加
- [x] `HouseworkAnalyticsAction.addHelper`・`AppScreen.houseworkAddHelper`を追加
- [x] `HouseworkAddHelperSheet` / `HouseworkAddHelperView`を新規作成（`#Preview`付き）
- [x] `HouseworkDetailActionContent`にボタン・表示判断・シートの提示を追加（`#Preview`を追加）
- [x] アクションをナビゲーションバー右側（単独のアイコンボタン＋「その他」メニュー）にまとめ直す
- [x] `doc/analytics_events.md`を更新

### Phase 3: 検証

- [x] ドメインのユニットテスト（配分の初期値・外せない担当者・合計ポイントの維持・完了以外では更新しない）
- [x] Storeのユニットテスト（保存内容とAnalytics）
- [x] 貢献度集計に追加後の配分が反映されることの確認 → **テストの追加は不要**と判断。`addHelpers`は`executors`を
      書き換えるだけで集計の経路は完了時と同じで、配分されたポイントで集計されることは既存テスト
      （`HouseworkContributionTest`の「複数人で担当した家事は、担当者それぞれに配分されたポイントと1件の達成で集計される」、
      `TodayMemberContributionTest`の同等のケース）が既に固定している
- [x] `make build-local-package` / SwiftLint / `make test-packages`（`swift-code-verification`スキル）
- [x] `make check-previews`
- [x] 家事詳細のアクションの出し分けのユニットテスト
- [x] `ios-code-reviewer`によるレビューと指摘対応
- [ ] シミュレータでの簡易E2E確認 → **未実施**。この機能は同居人グループに2人以上いることが前提で、
      E2E用シミュレータのアカウントがグループ未所属のため通せない

## 残課題（別対応）

- `HouseworkAddHelperView`と`HouseworkCompleteView`で、担当者チェックリスト・配分の調整・バリデーション文言の
  組み立て（`executorSection()` / `executorRows` / `allocationEntries` / `validationMessage` / `userName`）が
  100行ほど重複している。完了画面の見た目にも影響する変更になるため本対応では切り出さず、
  `Features/HouseworkFeature/Model/`の値型または共通のセクションViewへまとめるのは別Issueとする
- 手伝った人を足すと`executors`の並びが`memberIds`順（操作した人が先頭）になるため、旧アプリ向けの
  `executorId`（1人目の担当者）が元の担当者から入れ替わることがある。完了時と同じ性質で、
  旧アプリでの表示が少しずれるだけなので許容する（ADR-0023）

### Phase 4: PR

- [ ] PR作成（`pr-create`スキル）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/351
- 関連Issue: #291（担当者の複数選択）、#289（頑張り度）、#290（もう一度やった）、#293（ホームの今日の貢献）
- ADR: [0023](../adr/0023-housework-multiple-executors-with-allocated-points.md) / [0024](../adr/0024-housework-effort-level-as-separate-field.md) / [0009](../adr/0009-analytics-event-parameter-design.md)
- 既存実装（参考）:
  - `LocalPackage/Sources/Features/HouseworkFeature/HouseworkComplete/HouseworkCompleteSheet.swift`
  - `LocalPackage/Sources/Features/HouseworkFeature/HouseworkComplete/SubViews/HouseworkExecutorSelectionContent.swift`
  - `doc/strategy/housework-executor-selection.md`
