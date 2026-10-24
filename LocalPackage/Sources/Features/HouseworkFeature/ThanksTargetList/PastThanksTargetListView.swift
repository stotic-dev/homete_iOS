//
//  PastThanksTargetListView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 過去のありがとう漏れの一覧
///
/// 昨日から7日前までに同居人が終えた家事のうち、まだありがとうを伝えていないものを日付ごとに並べる。
/// 何を並べるかは呼び出し側が決め、この画面は渡された値を描いてタップを伝えるだけにする。
/// 一括でありがとうを送る操作（#453）を足せるよう、日ごとの家事をそのまま受け取る。
struct PastThanksTargetListView: View {

    @Environment(\.calendar) var calendar
    @Environment(\.locale) var locale

    let summary: PastThanksPromptSummary
    let ownUserId: String
    let members: CohabitantMemberList
    /// 行をタップした（メッセージを添えてありがとうを伝える）
    let onTapRow: (HouseworkBoardItem) -> Void
    /// ハートをタップした（ありがとうだけを伝える）
    let onTapThanks: (HouseworkBoardItem) -> Void

    var body: some View {
        contentView()
            // ホームからの遷移で地の色が変わらないよう、ホームと同じミルク色にする
            .background(.backgroundScreen)
            .navigationTitle(.localized("昨日までの家事"))
            .inlineNavigationBarTitleDisplayMode()
            .softTopScrollEdgeEffect()
    }

}

// MARK: UI定義

private extension PastThanksTargetListView {

    @ViewBuilder
    func contentView() -> some View {
        if summary.dailyItems.isEmpty {
            Text("この1週間で、まだありがとうを伝えていない家事はありません", bundle: #bundle)
                .font(with: .body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .space16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(summary.dailyItems) { dailyItems in
                    Section {
                        ForEach(dailyItems.items) { item in
                            houseworkItemRow(item)
                                .padding(.vertical, .space8)
                                .listRowBackground(Color.clear)
                            #if os(iOS)
                                .listRowSpacing(.zero)
                                .listRowSeparator(.hidden)
                            #endif
                        }
                    } header: {
                        Text(dailyItems.date.formatted(dateFormatStyle))
                            .font(with: .boldCaption)
                            .foregroundStyle(.textSecondary)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    func houseworkItemRow(_ item: HouseworkBoardItem) -> some View {
        let thanksStatus = HouseworkThanksStatus.make(item: item, ownUserId: ownUserId)
        return HouseBoardListRow(
            houseworkItem: item.originalItem,
            completionInfo: .init(
                executorNames: item.executors.compactMap { members.userName($0.userId) },
                thanksStatus: thanksStatus
            ),
            showsCompleteButton: false,
            // ありがとうを伝えるための一覧なので、ほかの操作は家事ボードや詳細に任せる
            showsMoreButton: false,
            onTapRow: { onTapRow(item) },
            onTapThanks: thanksStatus == .notSent ? { onTapThanks(item) } : nil,
            onTapComplete: {},
            menuContent: { EmptyView() }
        )
    }

    /// セクションの見出しの日付（例: 10月5日(日)）。家事の日付は端末の暦で決めているので、同じ暦とタイムゾーンで書く
    var dateFormatStyle: Date.FormatStyle {
        var style = Date.FormatStyle.dateTime.month().day().weekday()
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        style.locale = locale
        return style
    }

}

#if DEBUG
#Preview("PastThanksTargetListView_日付ごと") {
    let yesterday = Date.previewDate(year: 2026, month: 5, day: 17)
    let threeDaysAgo = Date.previewDate(year: 2026, month: 5, day: 15)
    NavigationStack {
        PastThanksTargetListView(
            summary: .init(
                dailyItems: [
                    .init(date: yesterday, items: [
                        .init(
                            originalItem: .makeForTest(
                                id: 1,
                                indexedDate: yesterday,
                                title: "洗濯",
                                point: 20,
                                state: .completed,
                                executorId: "otherUserId",
                                executedAt: .previewDate(year: 2026, month: 5, day: 17, hour: 21)
                            ),
                            isRegistered: true
                        ),
                        .init(
                            originalItem: .makeForTest(
                                id: 2,
                                indexedDate: yesterday,
                                title: "掃除",
                                point: 30,
                                state: .completed,
                                executorId: "otherUserId",
                                executedAt: .previewDate(year: 2026, month: 5, day: 17, hour: 9),
                                thanks: ["ownUserId": .init(comment: nil, sentAt: .distantPast)]
                            ),
                            isRegistered: true
                        ),
                    ]),
                    .init(date: threeDaysAgo, items: [
                        .init(
                            originalItem: .makeForTest(
                                id: 3,
                                indexedDate: threeDaysAgo,
                                title: "ゴミ出し",
                                point: 10,
                                state: .completed,
                                executorId: "otherUserId",
                                executedAt: .previewDate(year: 2026, month: 5, day: 15, hour: 7)
                            ),
                            isRegistered: true
                        ),
                    ]),
                ],
                notSentCount: 2,
                executorNames: ["はなこ"]
            ),
            ownUserId: "ownUserId",
            members: .init(
                value: [
                    .init(id: "ownUserId", userName: "自分"),
                    .init(id: "otherUserId", userName: "はなこ"),
                ],
                ownId: "ownUserId"
            ),
            onTapRow: { _ in },
            onTapThanks: { _ in }
        )
    }
    .setupEnvironmentForPreview()
}

#Preview("PastThanksTargetListView_家事なし") {
    NavigationStack {
        PastThanksTargetListView(
            summary: .init(dailyItems: [], notSentCount: 0, executorNames: []),
            ownUserId: "ownUserId",
            members: .init(value: [], ownId: "ownUserId"),
            onTapRow: { _ in },
            onTapThanks: { _ in }
        )
    }
    .setupEnvironmentForPreview()
}
#endif
