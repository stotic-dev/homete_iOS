//
//  ThanksTargetListView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// ありがとうを伝えられる家事の一覧
///
/// ダッシュボードの感謝の促しから開く。今日と昨日に同居人が終えた家事を並べ、
/// ハートのタップでありがとうだけを、行のタップでメッセージを添えて伝えられる。
/// 送った家事も一覧から消さず、送信済みの表示に切り替える（送った直後に行が消えて戸惑わないように）。
public struct ThanksTargetListView: View {

    @Environment(\.calendar) var calendar
    @Environment(\.now) var now
    @Environment(\.loginContext) var loginContext
    @Environment(\.cohabitantMembers) var members
    @Environment(HouseworkListStore.self) var houseworkListStore

    @CommonError var commonError
    /// メッセージを添えるハーフモーダルを出している家事
    @State var thankingItem: HouseworkBoardItem?
    /// 初めてありがとうを伝えたときの演出の回数
    @State var thanksFeedbackCount = 0
    /// ハーフモーダルで初めてありがとうを伝え、モーダルが閉じきるのを待って演出を出す
    @State var hasPendingThanksFeedback = false

    public static func make() -> some View {
        ThanksTargetListView()
    }

    public var body: some View {
        contentView(summary: ThanksPromptSummary.make(
            storedAllItems: houseworkListStore.items,
            members: members,
            ownUserId: loginContext.account.id,
            now: now,
            calendar: calendar
        ))
        .navigationTitle(.localized("ありがとうを伝える"))
        .inlineNavigationBarTitleDisplayMode()
        .softTopScrollEdgeEffect()
        .sheet(item: $thankingItem, onDismiss: dismissedThanksView) { item in
            HouseworkThanksView(
                item: item,
                sentThanks: item.sentThanks(ownUserId: loginContext.account.id),
                step: .commentPrompt
            ) {
                hasPendingThanksFeedback = true
            }
        }
        .thanksFeedback(trigger: thanksFeedbackCount)
        .commonError(content: $commonError)
        .trackScreenView(.thanksTargetList)
    }

}

// MARK: UI定義

private extension ThanksTargetListView {

    @ViewBuilder
    func contentView(summary: ThanksPromptSummary) -> some View {
        if summary.thankableItems.isEmpty {
            Text("ありがとうを伝えられる家事はありません", bundle: #bundle)
                .font(with: .body)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(summary.thankableItems) { item in
                    houseworkItemRow(item)
                        .padding(.vertical, .space8)
                        .listRowBackground(Color.clear)
                    #if os(iOS)
                        .listRowSpacing(.zero)
                        .listRowSeparator(.hidden)
                    #endif
                }
            }
            .listStyle(.plain)
        }
    }

    func houseworkItemRow(_ item: HouseworkBoardItem) -> some View {
        let thanksStatus = HouseworkThanksStatus.make(item: item, ownUserId: loginContext.account.id)
        return HouseBoardListRow(
            houseworkItem: item.originalItem,
            completionInfo: .init(
                executorNames: item.executors.compactMap { members.userName($0.userId) },
                thanksStatus: thanksStatus
            ),
            showsCompleteButton: false,
            // ありがとうを伝えるための一覧なので、ほかの操作は家事ボードや詳細に任せる
            showsMoreButton: false,
            onTapRow: { thankingItem = item },
            onTapThanks: thanksStatus == .notSent ? { Task { await sendThanks(to: item) } } : nil,
            onTapComplete: {},
            menuContent: { EmptyView() }
        )
    }

}

// MARK: プレゼンテーションロジック

private extension ThanksTargetListView {

    /// ハートのタップでは、メッセージを書かずにありがとうだけを伝える（コメントがないので通知は送らない）
    func sendThanks(to item: HouseworkBoardItem) async {
        guard let cohabitantId = loginContext.cohabitantId else { return }

        do {
            let isFirstThanks = try await houseworkListStore.perform(
                .sendThanks,
                on: item,
                now: now,
                account: loginContext.account,
                cohabitantId: cohabitantId,
                step: .commentPrompt
            )
            if isFirstThanks {
                thanksFeedbackCount += 1
            }
        } catch {
            commonError = .init(error: error)
        }
    }

    func dismissedThanksView() {
        guard hasPendingThanksFeedback else { return }

        hasPendingThanksFeedback = false
        thanksFeedbackCount += 1
    }

}

#if DEBUG
#Preview("ThanksTargetListView_未送信と送信済み") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    NavigationStack {
        ThanksTargetListView.make()
    }
    .environment(\.now, today)
    .environment(\.cohabitantMembers, .init(
        value: [
            .init(id: "ownUserId", userName: "自分"),
            .init(id: "otherUserId", userName: "はなこ"),
        ],
        ownId: "ownUserId"
    ))
    .environment(
        HouseworkListStore(items: [
            .init(
                items: [
                    .makeForTest(
                        id: 1,
                        indexedDate: today,
                        title: "洗濯",
                        point: 20,
                        state: .completed,
                        executorId: "otherUserId",
                        executedAt: .previewDate(year: 2026, month: 5, day: 18, hour: 9)
                    ),
                    .makeForTest(
                        id: 2,
                        indexedDate: today,
                        title: "掃除",
                        point: 30,
                        state: .completed,
                        executorId: "otherUserId",
                        executedAt: .previewDate(year: 2026, month: 5, day: 18, hour: 8),
                        thanks: ["ownUserId": .init(comment: nil, sentAt: .distantPast)]
                    ),
                ],
                metaData: .init(indexedDate: .init(value: today), expiredAt: .distantFuture)
            ),
        ])
    )
    .setupEnvironmentForPreview()
    .setupLoginContextForPreview()
}

#Preview("ThanksTargetListView_家事なし") {
    NavigationStack {
        ThanksTargetListView.make()
    }
    .environment(\.now, .previewDate(year: 2026, month: 5, day: 18))
    .environment(HouseworkListStore())
    .setupEnvironmentForPreview()
    .setupLoginContextForPreview()
}
#endif
