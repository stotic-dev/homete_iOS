# ホーム「今日の家事サマリー」メンバー別割合グラフ 実装方針

> 関連Issue: [#293 ホームで今日誰がどれぐらいやったか一目で確認できるようにしたい](https://github.com/stotic-dev/homete_iOS/issues/293)
> ブランチ: `feat/home-today-summary-graph`
> 前提となる機能: [今日の家事サマリー機能 実装方針](today-housework-summary.md)

## ステータス

- [x] 要件確定
- [x] 設計確定
- [ ] 実装完了
- [ ] テスト追加完了
- [ ] PRレビュー完了
- [ ] マージ完了

## 概要

今日誰がどれだけ家事をしたかを確認するには、今は分析画面の推移グラフを開く必要がある。
ホームの「今日の家事サマリー」に、メンバーごとの**完了した家事の数**と**獲得ポイント**の割合をドーナツグラフで表示し、ホームを開いただけで分かるようにする。

## 要件

### 機能要件

- 「今日の家事サマリー」の「達成率」の直下に、メンバー別の割合グラフを表示する
- グラフは次の2つのドーナツ。月間サマリー（`ContributionGraphSection`）と同じく、ページ型の `TabView` で左右にスワイプして切り替える
  1. **家事の数**: 今日完了した家事の件数の割合
  2. **ポイント**: 今日完了した家事で獲得したポイントの割合
- 集計対象は当日の `state == .completed` の家事のみ。実行者（`executorId`）ごとに集計する
  - 承認待ち（`pendingApproval`）は含めない（月間の `HouseworkContribution.make` と同じ基準）
  - 未完了（`incomplete`）・未登録のテンプレート家事は完了していないので対象外
- 同居人グループの全メンバーを凡例に表示する。今日まだ何もしていないメンバーも「0件 / 0pt」として含める
- 現在のメンバーに含まれない `executorId`（グループを抜けたユーザーなど）の家事は集計しない（月間サマリーと同じ扱い）
- メンバーの色は月間の「家事達成割合」ドーナツと同じく、Swift Charts がメンバー名ごとに自動で割り当てる
- 表示の出し分け

| 当日の家事の状態 | 割合グラフ |
|---|---|
| 家事0件（`.empty`） | 表示しない（既存の空表示のまま） |
| 家事はあるが、完了した家事が0件 | 表示しない |
| 完了した家事が1件以上（`.hasIncomplete` / `.allCompleted`） | 表示する |

### 非機能要件 / 制約

- データは `TodayHouseworkSummary.allItems`（`HouseworkListStore` 由来）から作る。新しい取得処理や Store は追加しない。達成率と同じデータなので、両者の数字がずれない
- メンバー名は `@Environment(\.cohabitantMembers)` から取得する（`ContributionSummaryComponent` と同じ）
- 集計ロジックはモデル側に置き、Swift Testing でユニットテストする
- モジュール依存は変えない（`HomeFeature` は既に `HouseworkFeature` に依存している）

## 設計方針

### 1. メンバー別集計をモデルに追加

`HouseworkFeature/Model/` に値オブジェクト `TodayMemberContribution` を追加し、`TodayHouseworkSummary` に集計メソッドを生やす。

`TodayHouseworkSummary.make(...)` にメンバーを渡すとシグネチャ変更が既存の呼び出し・テストに波及するため、メソッドとして分離する。

```swift
/// 当日のメンバー1人分の家事実績
public struct TodayMemberContribution: Equatable, Sendable, Identifiable {
    public let userId: String
    public let userName: String
    /// 今日完了した家事の数
    public let completedCount: Int
    /// 今日完了した家事で獲得したポイント
    public let point: Int

    public var id: String { userId }
}

public extension TodayHouseworkSummary {

    /// メンバーごとの当日の実績（`members.value` の順。自分が先頭）
    ///
    /// 完了（`completed`）の家事だけを実行者ごとに集計する。実績0件のメンバーも含む。
    func memberContributions(members: CohabitantMemberList) -> [TodayMemberContribution] {
        let completedByUser = Dictionary(grouping: allItems.filter { $0.state == .completed }) {
            $0.executorId ?? ""
        }
        return members.value.map { member in
            let items = completedByUser[member.id] ?? []
            return .init(
                userId: member.id,
                userName: member.userName,
                completedCount: items.count,
                point: items.reduce(0) { $0 + $1.point }
            )
        }
    }

}
```

グラフを出すかどうかの判定（誰か1件以上完了しているか）は、呼び出し側で `contains { $0.completedCount > 0 }` で判定する。凡例表示のためにメンバー全員を返すので、判定はモデルに持たせない。

### 2. 割合グラフのView

`HomeFeature/.../RegisteredContent/Components/` に `TodayContributionChartSection` を新設する。

- ページ型の `TabView` に「家事の数」「ポイント」の `SectorMark` ドーナツを2枚並べる（`innerRadius: .ratio(0.5)`, `angularInset: 2`, `.foregroundStyle(by: .value("名前", userName))`, `.chartLegend(position: .bottom, alignment: .center)`）。構成は `ContributionGraphSection` + `ContributionPieChart` に揃える
- `ContributionPieChart` は流用しない。`internal` であるうえ、タイトルと説明ポップオーバーの文言（「指定期間中において〜」）が月間用に固定されているため。今日の割合専用の小さなViewとして Home 側に持つ
- 高さ・ページインジケータの余白は `ContributionGraphSection` の値（`frame(height: 300)` / `padding(.bottom, .space48)`）を基準に、実機で見て調整する
- 実績0のメンバーは角度0の扇形になるが、データには含まれるので凡例には出る想定。Preview で凡例に表示されることを確認し、出ない場合は `chartForegroundStyleScale(domain:)` でメンバー名を明示する

### 3. サマリーへの組み込み

`TodayHouseworkSummaryComponent` で `@Environment(\.cohabitantMembers)` を受け取り、`progressContent` の直後に差し込む。

```swift
case .allCompleted:
    progressContent(progress: summary.progress)
    contributionChartContent(summary: summary)
    allCompletedContent()

case .hasIncomplete:
    progressContent(progress: summary.progress)
    contributionChartContent(summary: summary)
    incompleteListContent(summary: summary)
```

`contributionChartContent` は、完了した家事が1件もなければ何も表示しない。

### ファイル配置

| 種別 | パス | 役割 |
|---|---|---|
| 新規モデル | `LocalPackage/Sources/Features/HouseworkFeature/Model/TodayMemberContribution.swift` | メンバー1人分の当日実績 |
| 修正モデル | `LocalPackage/Sources/Features/HouseworkFeature/Model/TodayHouseworkSummary.swift` | `memberContributions(members:)` を追加 |
| 新規View | `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/RegisteredContent/Components/TodayContributionChartSection.swift` | 件数・ポイントのドーナツ2枚（ページ型TabView） |
| 修正View | `LocalPackage/Sources/Features/HomeFeature/HomeView/SubViews/RegisteredContent/Components/TodayHouseworkSummaryComponent.swift` | 達成率の直下にグラフを差し込み、Previewを追加 |
| 修正テスト | `LocalPackage/Tests/HouseworkFeatureTests/TodayHouseworkSummaryTest.swift` | `memberContributions` のテストを追加 |

## タスク

### Phase 1: 設計確定

- [x] グラフ形式: 件数・ポイントのドーナツ2つをスワイプで切り替え
- [x] 表示位置: 「達成率」の直下
- [x] 完了0件のときはグラフを非表示
- [x] 承認待ちは集計に含めない（completedのみ）
- [x] 実績0のメンバーも凡例に表示
- [x] 色は Swift Charts の自動割り当て（月間ドーナツと同じ）

### Phase 2: 実装

- [ ] `TodayMemberContribution` の追加
- [ ] `TodayHouseworkSummary.memberContributions(members:)` の追加
- [ ] ユニットテストの追加
  - completedのみを実行者ごとに件数・ポイント集計する
  - pendingApproval / incomplete は集計に含めない
  - 実績0のメンバーも0件・0ptで含まれる
  - メンバー外の `executorId` は集計しない
  - 並び順が `members.value`（自分が先頭）と一致する
- [ ] `TodayContributionChartSection` の実装
- [ ] `TodayHouseworkSummaryComponent` への組み込み
- [ ] Previewの追加・修正（複数メンバーで完了あり / 全て完了 / 完了0件でグラフ非表示）

### Phase 3: 検証

- [ ] `swift build` でビルド通過
- [ ] `swift-code-verification` スキルに沿って SwiftLint 通過
- [ ] ユニットテスト実行（追加分含む）通過
- [ ] スナップショットテスト（Prefire経由で自動生成）通過 / 必要なら参照画像を更新
- [ ] 実機/シミュレータで動作確認（凡例に実績0のメンバーが出ること、スワイプ切り替え）

### Phase 4: PR

- [ ] PR作成（`pr-create` スキル使用）
- [ ] Danger / CI通過
- [ ] レビュー対応
- [ ] マージ

## 関連リンク

- Issue: https://github.com/stotic-dev/homete_iOS/issues/293
- 既存実装（参考）:
  - `LocalPackage/Sources/Features/ContributionFeature/View/Summary/SubViews/ContributionGraphSection.swift`
  - `LocalPackage/Sources/Features/ContributionFeature/View/Common/ContributionPieChart.swift`
  - `LocalPackage/Sources/Features/ContributionFeature/Model/HouseworkContribution.swift`（月間の集計基準）
  - `LocalPackage/Sources/Features/HouseworkFeature/Model/TodayHouseworkSummary.swift`
