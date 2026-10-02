//
//  HouseworkDetailView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/08.
//

import HometeDomain
import HometeUI
import SwiftUI

public struct HouseworkDetailView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.loginContext.account) var account
    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(CohabitantStore.self) var cohabitantStore
    @LoadingState var loadingState

    @State var item: HouseworkBoardItem

    @CommonError var commonErrorContent

    public static func make(item: HouseworkBoardItem) -> some View {
        HouseworkDetailView(item: item)
    }

    public var body: some View {
        mainContent()
            .fullScreenLoadingIndicator(loadingState)
            .navigationTitle(item.title)
            .inlineNavigationBarTitleDisplayMode()
            .trailingToolbarItem {
                NavigationBarButton(label: .delete) {
                    Task {
                        await tappedDeleteHouseworkItem()
                    }
                }
            }
            .commonError(content: $commonErrorContent)
            .onChange(of: houseworkListStore.items) {
                didChangeItems()
            }
            .trackScreenView(.houseworkDetail)
    }

}

private extension HouseworkDetailView {

    func mainContent() -> some View {
        ScrollView {
            VStack(spacing: .space40) {
                HouseworkDetailItemListContent(
                    cohabitantMemberList: cohabitantStore.members,
                    item: item,
                    thanksMessages: HouseworkThanksMessage.make(item: item, memberList: cohabitantStore.members)
                )
                HouseworkDetailActionContent(
                    isLoading: $loadingState.isLoading,
                    commonErrorContent: $commonErrorContent,
                    account: account,
                    item: item,
                    canAddHelper: canAddHelper
                )
            }
            .padding(.horizontal, .space16)
            .padding(.bottom, .space24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .softTopScrollEdgeEffect()
    }

}

// MARK: プレゼンテーションロジック

private extension HouseworkDetailView {

    /// 手伝った人を足せるかどうか
    ///
    /// 完了済みで、まだ担当者になっていないメンバーがいて、人数の上限にも達していないときだけ足せる。
    /// 足せないときは「手伝った人を追加」の導線を出さない。
    var canAddHelper: Bool {
        guard item.state == .completed else { return false }

        return HouseworkExecutorAllocation.forAddingExecutors(
            memberIds: cohabitantStore.members.value.map(\.id),
            executors: item.executors,
            earnedPoint: item.earnedPoint
        )
        .canAddExecutor
    }

    func tappedDeleteHouseworkItem() async {
        guard let cohabitantId = account.cohabitantId else { return }

        do {
            try await houseworkListStore.remove(
                target: item.originalItem,
                cohabitantId: cohabitantId,
                isRegistered: item.isRegistered,
                step: .detail
            )
            dismiss()
        } catch {
            commonErrorContent = .init(error: error)
        }
    }

    func didChangeItems() {
        guard let targetItem = houseworkListStore.items.item(item.originalItem) else { return }

        withAnimation {
            item = .init(originalItem: targetItem, isRegistered: true)
        }
    }

}

#if DEBUG
#Preview {
    NavigationStack {
        HouseworkDetailView(
            item: .makeForPreview(
                title: "洗濯",
                point: 10
            )
        )
    }
    .environment(HouseworkListStore())
    .environment(CohabitantStore())
    .setupEnvironmentForPreview()
}

#Preview("HouseworkDetailView_通信中") {
    NavigationStack {
        HouseworkDetailView(
            loadingState: .init(store: .init(isLoading: true)),
            item: .makeForPreview(
                title: "洗濯",
                point: 10
            )
        )
    }
    .environment(HouseworkListStore())
    .environment(CohabitantStore())
    .setupEnvironmentForPreview()
    #if canImport(Prefire)
        .prefireIgnored()
    #endif
}
#endif
