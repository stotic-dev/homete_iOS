# 家事完了時の頑張り度 実装方針

> 関連Issue: [#289 家事の承認依頼する時に頑張り度を指定できる](https://github.com/stotic-dev/homete_iOS/issues/289)
> ブランチ: `feat/289-effort-param`
> データモデルの選定経緯: [ADR-0024](../adr/0024-housework-effort-level-as-separate-field.md)

## ステータス

- [x] 要件確定
- [x] 設計確定
- [x] 実装完了
- [x] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

同じ家事でも、日によって手間がかかる日とかからない日がある。家事を完了にするときに「どれだけ頑張ったか」を3段階で選べるようにし、頑張った分だけポイントを上乗せする。

Issue起票時点では承認フローがあったため「承認依頼する時」と書かれているが、[#292](remove-approval-state.md)で承認は廃止済み。本対応では[#291](housework-executor-selection.md)で追加した**完了用のハーフモーダル**に頑張り度の選択を足す。

## 要件

### 機能要件

#### 頑張り度の選択

1. 頑張り度は3段階から選ぶ

   | 表示 | ポイント |
   |---|---|
   | ふつう | 家事のポイントのまま（×1.0） |
   | がんばった | +20%（×1.2） |
   | 超頑張った | +50%（×1.5） |

2. 完了用のハーフモーダル（`HouseworkCompleteSheet`）で選ぶ。表示元は#291と同じく、家事詳細の「完了にする」と、クイックアクション（長押しメニュー）の「完了にする」（1件）
3. ハーフモーダルを開いたときは「ふつう」を選んでおく。そのまま完了にすれば今までと同じポイントになる
4. ハーフモーダルを通らない完了は「ふつう」で記録する
   - 複数選択の一括完了
   - 「もう一度やった」
5. 無料で使える（プレミアムの制限はかけない）

#### ポイントの計算

6. 上乗せ後のポイントは**切り上げ**にする（例：3pt × 1.2 = 3.6 → 4pt、1pt × 1.2 = 1.2 → 2pt）。ポイントが小さい家事でも、頑張った分が必ず増えるようにする
7. 担当者が2人以上のときは、**上乗せ後のポイント**を#291の配分（最大剰余方式）で分ける
8. 選べる担当者の人数の上限は、今までどおり**家事のポイント（上乗せ前）**で決める。頑張り度を切り替えても、選んだ担当者が上限を超えないようにするため

#### 変更

9. 完了した後に頑張り度は変えられない。変えたいときは「未完了に戻す」から完了にし直す
10. 「未完了に戻す」と頑張り度は「ふつう」に戻る

#### 表示

11. 完了した家事のポイントは、どこでも**上乗せ後のポイント**を出す
    - 家事ボードのセル、家事詳細、今日のサマリー、貢献度グラフ
12. 家事詳細に「頑張り度」の行を表示する（完了した家事のみ）
    - 「ポイント」欄は上乗せ後のポイントを出す
    - 「頑張り度」の行は、「ふつう」以外なら元のポイントからの内訳を添える（例：`がんばった（10pt → 12pt）`）
13. 同居人への完了通知には頑張り度を載せない（文言は変えない）

### 非機能要件 / 制約

- **旧バージョンのアプリと共存させる**。マイグレーションは行わない（[ADR-0023](../adr/0023-housework-multiple-executors-with-allocated-points.md)と同じ方針）
  - `effort` が無いドキュメントは「ふつう」として読む
  - 旧アプリは `executorId` と `point`（上乗せ前）しか読まないため、上乗せ分は旧アプリの表示・集計に反映されない。表示が少しずれるだけで壊れはしないので許容する
  - 旧アプリが `setData(merge: false)` で上書きすると `effort` も `executors` も消えるが、新アプリは「ふつう・満額配分」として読むので矛盾しない
- Firestoreルール・Cloud Functionsは変更しない（Houseworksのフィールドを検証していないため）
- 上乗せの計算はドメイン層の純粋な関数にして、ユニットテストで固定する
- 判定・計算はドメイン側に置き、Viewは結果を表示するだけにする（`presentation-logic-placement` ルール）

## 設計方針

### 1. ドメインモデル：`HouseworkEffort` を追加する

`LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkEffort.swift`（新規）

```swift
/// 家事を完了にしたときの頑張り度
public enum HouseworkEffort: String, CaseIterable, Codable, Sendable {

    /// ふつう
    case normal
    /// がんばった
    case hard
    /// 超頑張った
    case veryHard

    /// 家事のポイントに掛ける割合（%）
    public var ratePercentage: Int {
        switch self {
        case .normal: 100
        case .hard: 120
        case .veryHard: 150
        }
    }

    /// 上乗せ後のポイント（切り上げ）
    public func boostedPoint(_ point: Int) -> Int {
        (point * ratePercentage + 99) / 100
    }

}
```

- `Firestore.Encoder` で文字列（`"normal"` / `"hard"` / `"veryHard"`）として保存する
- 浮動小数点を使わず整数演算で切り上げる（`1.2 * 5` が `6.000000001` になって7に切り上がる、といった誤差を避ける）

### 2. `HouseworkItem` に `effort` を追加する

`LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkItem.swift`

```swift
/// 家事ポイント（頑張り度で上乗せする前）
public let point: Int
/// 頑張り度（完了していない家事では`.normal`）
public let effort: HouseworkEffort

/// 頑張り度で上乗せした後のポイント
public var earnedPoint: Int {
    effort.boostedPoint(point)
}
```

- `point` は上乗せ前のまま持つ。「未完了に戻す」で元のポイントに戻せるようにするため（[ADR-0024](../adr/0024-housework-effort-level-as-separate-field.md)）
- `executors[].point` の合計は `earnedPoint` と一致させる。集計（`HouseworkContribution` / `TodayHouseworkSummary`）はすでに `executors[].point` を足しているので変更不要
- デコードは `effort` を `decodeIfPresent` し、無ければ `.normal`
- `HouseworkEffort` 自体も、知らない値は `.normal` として読む（将来段階を増やしたときに、今のアプリで家事リスト全体のデコードが失敗しないように）
- `updateCompleted` では、担当者のポイントの合計が `effort.boostedPoint(point)` と一致することを `assert` で確かめる。配分と頑張り度を別々に受け取るため、組み合わせの取り違えに開発中に気付けるようにする
- `updateCompleted(at:executors:)` → `updateCompleted(at:executors:effort:)`
- `updateIncomplete()` は `effort` を `.normal` に戻す。`updateNotTodo()` は引き継ぐ
- `makeRedone` は `.normal` で作る。担当者は `.solo(userId:point:)` なので `point` と一致する
- メインの `init` の `effort` は必須引数にする（SwiftLintの `function_default_parameter_at_end` に合わせ、途中の引数にデフォルト値を置かない）。`executorId` を受け取る互換用の `init` は `.normal` で作る

### 3. 配分：`HouseworkExecutorAllocation` に頑張り度を持たせる

`LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkExecutorAllocation.swift`

もとは `totalPoint` が `let` で、選べる人数の上限と配分の両方に使っていた。これを分け、配分するポイントは頑張り度から計算する。

```swift
/// 家事のポイント（頑張り度で上乗せする前）。選べる人数の上限はこのポイントで決める
public let basePoint: Int
/// 頑張り度
public private(set) var effort: HouseworkEffort

/// 担当者に配分するポイント（頑張り度で上乗せした後）
public var totalPoint: Int { effort.boostedPoint(basePoint) }

public init(memberIds: [String], selectedIds: [String], basePoint: Int, effort: HouseworkEffort = .normal)

/// 頑張り度を変える。選んだ担当者と割合はそのままにして、配分するポイントだけ変える
public mutating func updateEffort(_ effort: HouseworkEffort)
```

- 頑張り度を配分の中に持たせることで、完了用ハーフモーダルは `allocation` だけを `@State` で持てばよく、頑張り度と配分するポイントを二重に管理しない
- `maxExecutorCount(basePoint:)` は上乗せ前のポイントで上限を決める。上乗せ後のポイントは必ず上乗せ前以上なので、頑張り度を切り替えても均等割りで0ptの担当者は出ない
- 割合を手で調整していた場合の0pt判定（`.zeroPoint`）は、今までどおり `validationError` で見る

### 4. UI：完了用ハーフモーダルに頑張り度を足す

`LocalPackage/Sources/Features/HouseworkFeature/HouseworkComplete/HouseworkCompleteSheet.swift`

```
(×)          完了にする            (✓)
頑張り度
 [ ふつう | がんばった | 超頑張った ]
 10pt → 12pt
担当者
 ☑ 自分        50%  6pt
 ☑ Bさん       50%  6pt
─────────────
 ▾ 配分を調整する
```

- 担当者のポイント表示が頑張り度で変わるため、頑張り度を担当者より上に置く
- 選択は `Picker` の `.segmented` スタイル。切り替えたら `allocation.updateEffort(_:)` を呼ぶ
- 「ふつう」以外のときは、セグメントの下に `10pt → 12pt` を出す（「ふつう」では出さない）
- 頑張り度の選択UIは `SubViews/HouseworkEffortSelectionContent.swift`（新規）に切り出す。選択中の頑張り度と内訳の文言は親から渡し、選択はクロージャで親に伝える
- 頑張り度の表示名と内訳の文言は `Model/HouseworkEffort+Presentation.swift`（新規）に置き、家事詳細と共用する
- 確定時は `allocation.effort` を `houseworkListStore.complete(..., effort:, ...)` に渡す
- `executorLimitMessage` の「この家事は◯ptなので」は上乗せ前のポイントのまま

### 5. Store：`HouseworkListStore.complete`

`LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkListStore.swift`

- 引数に `effort: HouseworkEffort` を追加し、`updateCompleted(at:executors:effort:)` に渡す
- 一括完了（`performBulk` → `perform(.complete)`）は `.normal` を渡す。担当者は今までどおり `.solo(userId:point:)` で満額
- 通知の内容は変えない

### 6. 表示の置き換え

| 対象 | 変更前 | 変更後 |
|---|---|---|
| `HouseworkBoardItem.point` | `originalItem.point` | `earnedPoint` に改名し `originalItem.earnedPoint` を返す（家事詳細の表示に使う）。`HouseworkItem.point`（上乗せ前）と同名で意味が逆になるのを避けるため |
| `HouseBoardListRow`（`HouseworkItem` を直接受け取る） | `houseworkItem.point` | `houseworkItem.earnedPoint` |
| `HouseworkDetailItemListContent` | — | 完了した家事に「頑張り度」の行を追加（例：`がんばった（10pt → 12pt）`） |

- 上乗せ前のポイントが必要な箇所（完了用ハーフモーダルの `basePoint`・人数上限の文言、一括完了の満額配分）は `originalItem.point` を参照する

### 7. Analytics

`housework` イベントの `complete` に `effort` パラメータを追加する。`doc/analytics_events.md` も同じPRで更新する。

| 値 | 意味 |
|---|---|
| `normal` | ふつう（一括完了は常にこれ） |
| `hard` | がんばった |
| `very_hard` | 超頑張った |

`complete` のうち `normal` 以外の割合で、頑張り度がどれだけ使われているかを見る。

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkEffort.swift` | 頑張り度と上乗せの計算 |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkItem.swift` | `effort` / `earnedPoint` の追加、互換デコード |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkExecutorAllocation.swift` | 上限用の `basePoint` と配分用の `totalPoint` を分ける、`updateEffort` |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkListStore.swift` | `complete` に `effort` を追加 |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/AnalyticsLog/HouseworkAnalyticsAction.swift` | `complete` に `effort` パラメータ |
| 修正ドメイン | `LocalPackage/Sources/HometeDomain/Utilities/DebugHelper/HouseworkItemHelper.swift` | プレビュー用ヘルパーに `effort` |
| 修正Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkBoardItem.swift` | `point` を上乗せ後に |
| 修正Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkListStore+QuickAction.swift` | 一括完了で `.normal` を渡す |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkComplete/HouseworkCompleteSheet.swift` | 頑張り度の選択を追加 |
| 新規View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkComplete/SubViews/HouseworkEffortSelectionContent.swift` | 頑張り度のセグメントと上乗せ後のポイント |
| 新規Model | `LocalPackage/Sources/Features/HouseworkFeature/Model/HouseworkEffort+Presentation.swift` | 頑張り度の表示名とポイントの内訳 |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkBoardView/SubViews/HouseBoardListRow.swift` | 上乗せ後のポイントを表示 |
| 修正Preview | `LocalPackage/Sources/Features/HouseworkFeature/Preview/HouseworkUtil.swift` | プレビュー用ヘルパーに `effort` |
| 修正View | `LocalPackage/Sources/Features/HouseworkFeature/HouseworkDetailView/SubViews/HouseworkDetailItemListContent.swift` | 頑張り度の行（ポイントの内訳付き） |
| 修正ドキュメント | `doc/analytics_events.md` | `effort` パラメータ |
| 新規ADR | `doc/adr/0024-housework-effort-level-as-separate-field.md` | データの持ち方の選定 |

## タスク

### Phase 1: 設計確定

- [x] 頑張り度は「ふつう / がんばった / 超頑張った」の3段階。×1.0 / +20% / +50%
- [x] 完了用のハーフモーダル（#291）で選ぶ。初期値は「ふつう」
- [x] 一括完了・「もう一度やった」は「ふつう」
- [x] 端数は切り上げ
- [x] 完了後は変えられない（未完了に戻して完了にし直す）
- [x] 表示・集計はすべて上乗せ後のポイント。家事詳細に頑張り度と内訳を出す
- [x] 完了通知には載せない
- [x] 無料機能
- [x] `point` は上乗せ前のまま持ち、`effort` を別フィールドで保存する（ADR-0024）

### Phase 2: 実装

コミットは対応単位で分ける（[.claude/rules/git-commit.md](../../.claude/rules/git-commit.md)）。

- [x] ドメイン層: `HouseworkEffort` / `HouseworkItem` / `HouseworkExecutorAllocation` / `HouseworkListStore`（ユニットテスト含む）
- [x] 完了用ハーフモーダルに頑張り度の選択を追加
- [x] 家事ボード・家事詳細の表示を上乗せ後のポイントに
- [x] Analyticsの `effort` パラメータ
- [x] `#Preview` の追加（頑張り度のセグメント、頑張り度付きの家事詳細）
- [x] ドキュメント更新（`doc/analytics_events.md`）

### Phase 3: 検証

- [x] `make build-local-package` でビルド通過
- [x] `swift-code-verification` スキルに沿って SwiftLint 通過
- [x] `make test-packages` 通過（追加分含む）
- [x] `make check-previews` 通過
- [ ] スナップショットテスト（Prefire経由で自動生成）の参照画像をXcode Cloudで更新
- [ ] シミュレータで簡易E2E確認（がんばったで完了 → 詳細でポイントの内訳 → 未完了に戻す）

### Phase 4: PR

- [ ] PR作成（`pr-create` スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/289
- 既存実装（参考）:
  - `LocalPackage/Sources/Features/HouseworkFeature/HouseworkComplete/HouseworkCompleteSheet.swift`
  - `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkExecutorAllocation.swift`
  - `LocalPackage/Sources/HometeDomain/Cohabitant/Housework/HouseworkItem.swift`
- 関連ドキュメント:
  - [doc/strategy/housework-executor-selection.md](housework-executor-selection.md)
  - [doc/strategy/remove-approval-state.md](remove-approval-state.md)
  - [ADR-0023 家事の担当者を複数人にし、担当者ごとに割合とポイントを保存する](../adr/0023-housework-multiple-executors-with-allocated-points.md)
  - [doc/analytics_events.md](../analytics_events.md)
