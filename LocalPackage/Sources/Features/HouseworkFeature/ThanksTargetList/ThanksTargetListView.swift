//
//  ThanksTargetListView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// ありがとうを伝えられる家事の一覧
///
/// 何を並べるかは呼び出し側が決め、この画面は渡された値を描いてタップを伝えるだけにする。
/// 末尾には、昨日より前の家事を並べる過去のありがとう漏れの一覧へのリンクを置く。
/// ホームの過去の促しを出し切った後も、過去の一覧に行けるようにするため。
struct ThanksTargetListView: View {

    let summary: ThanksPromptSummary
    let ownUserId: String
    let members: CohabitantMemberList
    /// 行をタップした（メッセージを添えてありがとうを伝える）
    let onTapRow: (HouseworkBoardItem) -> Void
    /// ハートをタップした（ありがとうだけを伝える）
    let onTapThanks: (HouseworkBoardItem) -> Void
    /// 過去のありがとう漏れの一覧へのリンクをタップした
    let onTapPastList: () -> Void

    var body: some View {
        contentView()
            // ホームからの遷移で地の色が変わらないよう、ホームと同じミルク色にする
            .background(.backgroundScreen)
            .navigationTitle(.localized("ありがとうを伝える"))
            .inlineNavigationBarTitleDisplayMode()
            .softTopScrollEdgeEffect()
    }

}

// MARK: UI定義

private extension ThanksTargetListView {

    @ViewBuilder
    func contentView() -> some View {
        if summary.thankableItems.isEmpty {
            VStack(spacing: .space16) {
                Text("ありがとうを伝えられる家事はありません", bundle: #bundle)
                    .font(with: .body)
                pastListLink()
            }
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
                pastListLink()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .space8)
                    .listRowBackground(Color.clear)
                #if os(iOS)
                    .listRowSeparator(.hidden)
                #endif
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    /// 過去のありがとう漏れの一覧へのリンク。今日の家事の邪魔をしないよう、控えめな見た目にする
    func pastListLink() -> some View {
        Button {
            onTapPastList()
        } label: {
            HStack(spacing: .space4) {
                Text("昨日までの家事を見る", bundle: #bundle)
                Image(systemName: "chevron.right")
                    .accessibilityHidden(true)
            }
            .font(with: .caption)
            .foregroundStyle(.textSecondary)
        }
        .buttonStyle(.plain)
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

}

#if DEBUG
#Preview("ThanksTargetListView_未送信と送信済み") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    NavigationStack {
        ThanksTargetListView(
            summary: .init(
                thankableItems: [
                    .init(
                        originalItem: .makeForTest(
                            id: 1,
                            indexedDate: today,
                            title: "洗濯",
                            point: 20,
                            state: .completed,
                            executorId: "otherUserId",
                            executedAt: .previewDate(year: 2026, month: 5, day: 18, hour: 9)
                        ),
                        isRegistered: true
                    ),
                    .init(
                        originalItem: .makeForTest(
                            id: 2,
                            indexedDate: today,
                            title: "掃除",
                            point: 30,
                            state: .completed,
                            executorId: "otherUserId",
                            executedAt: .previewDate(year: 2026, month: 5, day: 18, hour: 8),
                            thanks: ["ownUserId": .init(comment: nil, sentAt: .distantPast)]
                        ),
                        isRegistered: true
                    ),
                ],
                notSentCount: 1,
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
            onTapThanks: { _ in },
            onTapPastList: {}
        )
    }
    .setupEnvironmentForPreview()
}

#Preview("ThanksTargetListView_家事なし") {
    NavigationStack {
        ThanksTargetListView(
            summary: .init(thankableItems: [], notSentCount: 0, executorNames: []),
            ownUserId: "ownUserId",
            members: .init(value: [], ownId: "ownUserId"),
            onTapRow: { _ in },
            onTapThanks: { _ in },
            onTapPastList: {}
        )
    }
    .setupEnvironmentForPreview()
}
#endif
