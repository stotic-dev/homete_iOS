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
            switch summary.displayState {
            case .empty:
                titleText
                    .frame(maxWidth: .infinity, alignment: .leading)
                emptyContent()

            case .allCompleted:
                progressContent
                memberShareContent
                allCompletedContent()

            case .hasIncomplete:
                progressContent
                memberShareContent
                incompleteListContent
            }
        }
    }

    var titleText: some View {
        Text("今日の家事", bundle: #bundle)
            .font(with: .headLineM)
            .foregroundStyle(.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    /// 見出しと、終わった家事の数（3/5）・進み具合のバー
    var progressContent: some View {
        VStack(spacing: .space16) {
            HStack(alignment: .firstTextBaseline) {
                titleText
                Spacer()
                progressCountText
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        .localized(
                            "\(summary.allItems.count)件中\(summary.finishedCount)件終わりました",
                            comment: "1つめは今日の家事の数、2つめは終わった家事の数"
                        )
                    )
            }
            SoftProgressBar(value: summary.progress)
                .accessibilityHidden(true)
        }
    }

    /// 終わった数を大きく、全体の数を小さく添える（例: 3/5）
    var progressCountText: some View {
        HStack(alignment: .firstTextBaseline, spacing: .zero) {
            Text(verbatim: "\(summary.finishedCount)")
                .font(with: .number)
                .foregroundStyle(.textPrimary)
            Text(verbatim: "/\(summary.allItems.count)")
                .font(with: .headLineS)
                .monospacedDigit()
                .foregroundStyle(.textSecondary)
        }
    }

    /// 誰も家事を終えていない間は、分担を表示しない
    @ViewBuilder
    var memberShareContent: some View {
        let contributions = summary.memberContributions(members: members)
        if contributions.contains(where: { $0.completedCount > 0 }) {
            // ポイントが0の家事だけのときも分担が見えるよう、件数で塗り分ける
            let usesPoint = contributions.contains { $0.point > 0 }
            MemberShareSummary(items: contributions.map { contribution in
                .init(
                    id: contribution.userId,
                    name: contribution.userName,
                    value: usesPoint ? contribution.point : contribution.completedCount,
                    detail: .localized(
                        "\(contribution.completedCount)件・\(contribution.point)pt",
                        comment: "メンバーが終えた家事の件数と、もらったポイント"
                    )
                )
            })
        }
    }

    func emptyContent() -> some View {
        VStack(spacing: .space8) {
            HometteView(.cheer)
                .padding(.bottom, .space8)
            Text("今日の家事がありません", bundle: #bundle)
                .font(with: .headLineS)
                .foregroundStyle(.textPrimary)
            Text("今日やる家事を登録すると、みんなの進み具合がここに表示されます", bundle: #bundle)
                .font(with: .body)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
            Button(.localized("家事を設定する"), action: onTapRegister)
                .primaryButtonStyle()
                .padding(.top, .space16)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .space8)
    }

    func allCompletedContent() -> some View {
        VStack(spacing: .space8) {
            HometteView(.rest, size: .medium)
            Text("今日の家事は、ぜんぶ終わりました", bundle: #bundle)
                .font(with: .headLineS)
                .foregroundStyle(.textPrimary)
            Text("おつかれさまでした。ゆっくり休んでくださいね", bundle: #bundle)
                .font(with: .body)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .space8)
    }

    var incompleteListContent: some View {
        VStack(spacing: .space16) {
            HStack {
                Text("未完了の家事", bundle: #bundle)
                    .font(with: .headLineS)
                    .foregroundStyle(.textPrimary)
                Spacer()
                Text("\(summary.incompleteItems.count)件", bundle: #bundle)
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
                Button(.localized("もっと表示する"), action: onTapShowMore)
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
