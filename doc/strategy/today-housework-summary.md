# 今日の家事サマリー機能 実装方針

## 概要

ダッシュボード（`RegisteredContent`）のTOPに「当日の家事サマリー」を表示する。
当日の家事進捗を可視化し、未完了家事を素早く把握・操作できる導線を提供する。

## ステータス

- ステータス: 実装準備中
- 起票日: 2026-05-18
- 関連ブランチ: `feat/dashboard_today_housework_summary`

## 要件

### 機能要件

1. **進捗表示**
   - 当日（`Date.now`基準の `indexedDate`）の家事の達成率を表示する
   - 達成率 = `完了家事数 / 全家事数`
   - 「完了」とは `HouseworkState.completed`
   - 「未完了」とは `HouseworkState.incomplete` および `HouseworkState.pendingApproval`
2. **未完了家事リスト**
   - 当日の未完了家事を最大4件まで表示する
   - 5件以上ある場合は「もっと表示する」ボタンを表示する
   - 「もっと表示する」をタップで未完了家事詳細画面へ **push 遷移** する
3. **未完了家事詳細画面**
   - 当日のすべての未完了家事をリストで表示する
4. **空状態の出し分け**
   - 当日に家事が**存在しない**場合：「今日の家事がない」旨のメッセージ + 家事登録の導線（`RegisterHouseworkView` を**モーダル表示**）
   - 当日の家事が**全て完了**している場合：「今日の家事が完了した」旨のメッセージ

### 表示パターンまとめ

| 当日の家事の状態 | 進捗表示 | 未完了リスト | 「もっと表示する」 | 空表示メッセージ | 家事登録導線 |
|---|---|---|---|---|---|
| 家事0件 | × | × | × | 「今日の家事がない」 | ○（モーダル） |
| 全て完了 | ○（100%） | × | × | 「今日の家事が完了した」 | × |
| 未完了 1〜4件 | ○ | ○（全件） | × | × | × |
| 未完了 5件以上 | ○ | ○（4件） | ○ | × | × |

### 非機能要件

- 既存DIパターン（`AppDependencies`）に準拠する
- Swift 6 strict concurrency に準拠する
- `HouseworkListStore` のリアルタイム反映に追従して、サマリーが自動更新される

## 既存実装との関係

- 現状の `RegisteredContent` には `TodayHouseworkListContent`（空表示のみ未実装）が存在する
- 役割が重複するため、**`TodayHouseworkListContent.swift` は削除し、新規ファイルとして本サマリーUIを実装する**
- データソースは既存の `HouseworkListStore`（`AppTabView` で生成済み）を流用する
- `HomeView` → `RegisteredContent` まで `HouseworkListStore` を環境注入する経路を追加する

## 設計概要

### 新規ドメインモデル

`HouseworkFeature` 配下に、当日サマリー用の値オブジェクトを追加する。

```
TodayHouseworkSummary
├ allItems: [HouseworkItem]       // 当日の全家事
├ incompleteItems: [HouseworkItem] // incomplete + pendingApproval
├ progress: Double                  // 達成率 (0.0〜1.0)
├ displayState: DisplayState        // .empty / .allCompleted / .hasIncomplete
└ hasMoreIncomplete: Bool           // 未完了 > 4 件か
```

- 「未完了」フィルタロジック、進捗率算出、表示状態判定をモデル内に集約してテスト容易性を担保する

### 新規View

| View | 配置 | 役割 |
|---|---|---|
| `TodayHouseworkSummaryComponent` | `HomeFeature/HomeView/SubViews/RegisteredContent/Components/` | サマリー本体（進捗 + 未完了リスト + 状態出し分け） |
| `IncompleteHouseworkListView` | `HouseworkFeature/IncompleteHouseworkListView/` | 全未完了家事リスト画面（push遷移先） |

### ナビゲーション

`RegisteredContent` 側で `NavigationStack` 配下にあることを利用し、`navigationDestination` で `IncompleteHouseworkListView` へpushする。
ルート定義は `HomeFeature` 配下に追加（例: `RegisteredContentRoute`）するか、既存の `AppRoute` 拡張で対応する。

### 行アイテム表示

既存の `HouseBoardListRow`（`HouseworkFeature` 内）を流用可能か検討する。難しい場合は同等のシンプルな行コンポーネントを新設する。

## ファイル変更一覧（予定）

### 追加

- `LocalPackage/Sources/Features/HouseworkFeature/Model/TodayHouseworkSummary.swift`
- `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/RegisteredContent/Components/TodayHouseworkSummaryComponent.swift`
- `LocalPackage/Sources/Features/HouseworkFeature/IncompleteHouseworkListView/IncompleteHouseworkListView.swift`
- `LocalPackage/Tests/HouseworkFeatureTests/TodayHouseworkSummaryTest.swift`

### 削除

- `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/RegisteredContent/Components/TodayHouseworkListContent.swift`

### 変更

- `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/RegisteredContent/RegisteredContent.swift`
  - `TodayHouseworkListContent` の参照を `TodayHouseworkSummaryComponent` に差し替え
  - `HouseworkListStore` を Environment から受け取る
- `LocalPackage/Sources/Features/HomeFeature/HomeView/HomeView.swift`
  - `HouseworkListStore` を引数で受け取り `RegisteredContent` まで注入
- `LocalPackage/Sources/AppRoot/AppTabView.swift`
  - `HomeView.make(...)` に `houseworkListStore` を渡す

## タスク一覧

進捗管理用チェックリスト。完了したら `- [ ]` を `- [x]` に更新する。

### Phase 1: ドメインモデル

- [ ] **T-1** `TodayHouseworkSummary` 値オブジェクトの実装
  - 当日の `HouseworkItem` 配列から初期化
  - `incompleteItems`（incomplete + pendingApproval）の抽出
  - `progress`（達成率: completed / all）の算出
  - `displayState`（empty / allCompleted / hasIncomplete）の判定
  - `displayIncompleteItems`（最大4件）と `hasMoreIncomplete` フラグ
- [ ] **T-2** `TodayHouseworkSummary` のユニットテスト
  - 家事0件 → `.empty`
  - 全完了 → `.allCompleted`、progress = 1.0
  - 未完了あり → `.hasIncomplete`、progress 計算検証
  - 未完了4件以下 / 5件以上で `hasMoreIncomplete` が正しく切り替わる
  - `incomplete` と `pendingApproval` の両方を未完了として集計

### Phase 2: 未完了家事詳細画面

- [ ] **T-3** `IncompleteHouseworkListView` の実装
  - 当日の全未完了家事をリスト表示
  - 既存 `HouseBoardListRow` の流用 or 同等の行ビュー追加
- [ ] **T-4** ナビゲーションルートの追加（push遷移用）

### Phase 3: サマリーコンポーネント

- [ ] **T-5** `TodayHouseworkSummaryComponent` の実装
  - 進捗バー / ラベル表示
  - 未完了アイテムのリスト（最大4件）
  - 「もっと表示する」ボタン（条件付き表示）
  - 空状態のメッセージ + アクション（モーダル表示 or なし）
- [ ] **T-6** 既存 `TodayHouseworkListContent.swift` の削除

### Phase 4: 組み込み

- [ ] **T-7** `RegisteredContent` への組み込み + `HouseworkListStore` の環境注入経路追加
- [ ] **T-8** `HomeView` の引数追加と `AppTabView` 側の呼び出し更新

### Phase 5: 検証

- [ ] **T-9** `swift-code-verification` スキルに従ったビルド・SwiftLint・ユニットテスト実行
- [ ] **T-10** Preview / 実機での表示確認（4パターンの分岐）

## オープン事項

実装中に判断が必要になった場合に追記する。

- なし
