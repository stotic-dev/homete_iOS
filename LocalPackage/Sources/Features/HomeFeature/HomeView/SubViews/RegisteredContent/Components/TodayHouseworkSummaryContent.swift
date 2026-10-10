//
//  TodayHouseworkSummaryContent.swift
//  homete
//

import HometeDomain
import HometeUI
import HouseworkFeature
import SwiftUI

/// 「今日の家事サマリー」のUI
///
/// 渡されたサマリーを描画してタップを伝えるだけで、シートの表示や画面遷移は呼び出し側が行う。
/// チュートリアルでも同じViewにサンプルの家事を渡して表示する。
struct TodayHouseworkSummaryContent<RowMenu: View>: View {

    let summary: TodayHouseworkSummary
    /// 割合グラフの凡例に出すメンバー
    let members: CohabitantMemberList
    let onTapRegister: () -> Void
    let onTapItem: (HouseworkBoardItem) -> Void
    /// 行の完了ボタンのタップ。完了のハーフモーダルは呼び出し側が出す
    let onTapComplete: (HouseworkBoardItem) -> Void
    let onTapShowMore: () -> Void
    /// 未完了の家事を長押ししたときと、その他ボタンのメニューの中身
    @ViewBuilder let rowMenu: (HouseworkBoardItem) -> RowMenu

    var body: some View {
        contentView
    }

}

// MARK: - UI定義

private extension TodayHouseworkSummaryContent {

    var contentView: some View {
        VStack(spacing: .space24) {
            Text("今日の家事サマリー")
                .font(with: .headLineM)
                .frame(maxWidth: .infinity, alignment: .leading)
            switch summary.displayState {
            case .empty:
                emptyContent()

            case .allCompleted:
                progressContent(progress: summary.progress)
                contributionChartContent
                allCompletedContent()

            case .hasIncomplete:
                progressContent(progress: summary.progress)
                contributionChartContent
                incompleteListContent
            }
        }
    }

    func progressContent(progress: Double) -> some View {
        VStack(spacing: .space8) {
            HStack {
                Text("達成率")
                    .font(with: .body)
                Spacer()
                Text(progress.formatted(.percent.precision(.fractionLength(0))))
                    .font(with: .headLineS)
            }
            ProgressView(value: progress)
                .tint(.fillAccent)
        }
    }

    /// 誰も家事を完了していない間は、割合グラフを表示しない
    @ViewBuilder
    var contributionChartContent: some View {
        let contributions = summary.memberContributions(members: members)
        if contributions.contains(where: { $0.completedCount > 0 }) {
            TodayContributionChartSection(contributions: contributions)
        }
    }

    func emptyContent() -> some View {
        VStack(spacing: .zero) {
            Text("今日の家事がありません")
                .font(with: .headLineS)
            Spacer()
                .frame(height: .space8)
            Text("今日の家事を確認して、家事リストを設定しましょう！")
                .font(with: .body)
                .multilineTextAlignment(.center)
            Spacer()
                .frame(height: .space24)
            Button("家事を設定する", action: onTapRegister)
                .primaryButtonStyle()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .space56)
        .overlay {
            RoundedRectangle(radius: .radius12)
                .stroke(style: .init(lineWidth: 2, dash: [8]))
                .foregroundStyle(.fillAccent)
        }
    }

    func allCompletedContent() -> some View {
        VStack(spacing: .space8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.fillAccent)
            Text("今日の家事は全て完了しました")
                .font(with: .headLineS)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .space24)
    }

    var incompleteListContent: some View {
        VStack(spacing: .space16) {
            HStack {
                Text("未完了の家事")
                    .font(with: .headLineS)
                    .foregroundStyle(.textPrimary)
                Spacer()
                Text("\(summary.incompleteItems.count)件")
                    .font(with: .body)
                    .foregroundStyle(.textPrimary)
            }
            ForEach(summary.displayIncompleteItems) { item in
                houseworkItemRow(item)
                    .contextMenu {
                        rowMenu(item)
                    }
            }
            if summary.hasMoreIncomplete {
                Button("もっと表示する", action: onTapShowMore)
                    .subPrimaryButtonStyle()
            }
        }
    }

    func houseworkItemRow(_ item: HouseworkBoardItem) -> some View {
        HouseBoardListRow(
            houseworkItem: item.originalItem,
            // 未完了の家事には担当者もありがとうも無いので、完了リスト向けの表示は渡さない
            completionInfo: nil,
            showsCompleteButton: item.state == .incomplete,
            // 未完了の家事だけを並べる画面で、未完了には必ず「完了にする」「やらない」が出る
            showsMoreButton: true,
            onTapRow: { onTapItem(item) },
            onTapThanks: nil,
            onTapComplete: { onTapComplete(item) },
            menuContent: { rowMenu(item) }
        )
    }

}

#if DEBUG
#Preview("TodayHouseworkSummaryContent_家事なし") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    ScrollView {
        TodayHouseworkSummaryContent(
            summary: .make(
                storedAllItems: .init(value: []),
                template: nil,
                now: today,
                calendar: .japanese,
                storagePolicy: .premium
            ),
            members: .init(value: [], ownId: "ownUserId"),
            onTapRegister: {},
            onTapItem: { _ in },
            onTapComplete: { _ in },
            onTapShowMore: {},
            rowMenu: { _ in EmptyView() }
        )
        .padding(.horizontal, .space16)
    }
    .setupEnvironmentForPreview()
}

#Preview("TodayHouseworkSummaryContent_全て完了") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    ScrollView {
        TodayHouseworkSummaryContent(
            summary: .make(
                storedAllItems: .init(value: [
                    .init(
                        items: [
                            .makeForTest(
                                id: 1,
                                indexedDate: today,
                                title: "洗濯",
                                point: 20,
                                state: .completed
                            ),
                            .makeForTest(
                                id: 2,
                                indexedDate: today,
                                title: "掃除",
                                point: 30,
                                state: .completed
                            ),
                        ],
                        metaData: .init(
                            indexedDate: .init(value: today),
                            expiredAt: .distantFuture
                        )
                    ),
                ]),
                template: nil,
                now: today,
                calendar: .japanese,
                storagePolicy: .premium
            ),
            members: .init(value: [], ownId: "ownUserId"),
            onTapRegister: {},
            onTapItem: { _ in },
            onTapComplete: { _ in },
            onTapShowMore: {},
            rowMenu: { _ in EmptyView() }
        )
        .padding(.horizontal, .space16)
    }
    .setupEnvironmentForPreview()
}

#Preview("TodayHouseworkSummaryContent_未完了4件以下") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    ScrollView {
        TodayHouseworkSummaryContent(
            summary: .make(
                storedAllItems: .init(value: [
                    .init(
                        items: [
                            .makeForTest(
                                id: 1,
                                indexedDate: today,
                                title: "洗濯",
                                point: 20,
                                state: .incomplete
                            ),
                            .makeForTest(
                                id: 2,
                                indexedDate: today,
                                title: "掃除",
                                point: 30,
                                state: .incomplete
                            ),
                            .makeForTest(
                                id: 3,
                                indexedDate: today,
                                title: "掃除",
                                point: 30,
                                state: .completed,
                                executorId: "ownUserId"
                            ),
                        ],
                        metaData: .init(
                            indexedDate: .init(value: today),
                            expiredAt: .distantFuture
                        )
                    ),
                ]),
                template: nil,
                now: today,
                calendar: .japanese,
                storagePolicy: .premium
            ),
            members: .init(
                value: [
                    .init(id: "ownUserId", userName: "自分"),
                    .init(id: "otherUserId", userName: "同居人"),
                ],
                ownId: "ownUserId"
            ),
            onTapRegister: {},
            onTapItem: { _ in },
            onTapComplete: { _ in },
            onTapShowMore: {},
            rowMenu: { _ in EmptyView() }
        )
        .padding(.horizontal, .space16)
    }
    .setupEnvironmentForPreview()
}

#Preview("TodayHouseworkSummaryContent_未完了5件以上") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    ScrollView {
        TodayHouseworkSummaryContent(
            summary: .make(
                storedAllItems: .init(value: [
                    .init(
                        items: [
                            .makeForTest(
                                id: 1,
                                indexedDate: today,
                                title: "洗濯",
                                point: 20,
                                state: .incomplete
                            ),
                            .makeForTest(
                                id: 2,
                                indexedDate: today,
                                title: "掃除",
                                point: 30,
                                state: .incomplete
                            ),
                            .makeForTest(
                                id: 3,
                                indexedDate: today,
                                title: "掃除",
                                point: 30,
                                state: .incomplete
                            ),
                            .makeForTest(
                                id: 4,
                                indexedDate: today,
                                title: "ゴミ出し",
                                point: 20,
                                state: .incomplete
                            ),
                            .makeForTest(
                                id: 5,
                                indexedDate: today,
                                title: "買い物",
                                point: 30,
                                state: .incomplete
                            ),
                            .makeForTest(
                                id: 6,
                                indexedDate: today,
                                title: "アイロン",
                                point: 30,
                                state: .incomplete
                            ),
                        ],
                        metaData: .init(
                            indexedDate: .init(value: today),
                            expiredAt: .distantFuture
                        )
                    ),
                ]),
                template: nil,
                now: today,
                calendar: .japanese,
                storagePolicy: .premium
            ),
            members: .init(value: [], ownId: "ownUserId"),
            onTapRegister: {},
            onTapItem: { _ in },
            onTapComplete: { _ in },
            onTapShowMore: {},
            rowMenu: { _ in EmptyView() }
        )
        .padding(.horizontal, .space16)
    }
    .setupEnvironmentForPreview()
}
#endif
