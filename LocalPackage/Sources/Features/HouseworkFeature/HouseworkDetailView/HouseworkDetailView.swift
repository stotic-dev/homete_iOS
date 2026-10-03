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
    @Environment(\.now) var now
    @Environment(\.loginContext.account) var account
    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(CohabitantStore.self) var cohabitantStore
    @LoadingState var loadingState

    @State var item: HouseworkBoardItem
    @State var isPresentedCompleteSheet = false
    @State var isPresentedThanksView = false
    @State var isPresentedAddHelperSheet = false

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
                HouseworkDetailActionContent(
                    primaryAction: primaryAction,
                    menuActions: menuActions,
                    onTap: tappedAction
                )
                .disabled(loadingState.isLoading)
            }
            .sheet(isPresented: $isPresentedCompleteSheet) {
                HouseworkCompleteSheet(item: item, step: .detail)
            }
            .sheet(isPresented: $isPresentedThanksView) {
                HouseworkThanksView(item: item, sentThanks: item.sentThanks(ownUserId: account.id))
            }
            .sheet(isPresented: $isPresentedAddHelperSheet) {
                HouseworkAddHelperSheet(item: item, step: .detail)
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
            HouseworkDetailItemListContent(
                cohabitantMemberList: cohabitantStore.members,
                item: item,
                thanksMessages: HouseworkThanksMessage.make(item: item, memberList: cohabitantStore.members)
            )
            .padding(.horizontal, .space16)
            .padding(.bottom, .space24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .softTopScrollEdgeEffect()
    }

}

// MARK: プレゼンテーションロジック

private extension HouseworkDetailView {

    /// この家事に対して行えるアクション（ナビゲーションバーとメニューに出す順番）
    var actions: [HouseworkDetailAction] {
        HouseworkDetailAction.actions(for: item, ownUserId: account.id, canAddHelper: canAddHelper)
    }

    /// ナビゲーションバーに単独のボタンとして出すアクション
    var primaryAction: HouseworkDetailAction? {
        actions.first(where: \.isPrimary)
    }

    /// 「その他」のメニューに入れるアクション
    var menuActions: [HouseworkDetailAction] {
        actions.filter { !$0.isPrimary }
    }

    /// 手伝った人を足せるかどうか
    var canAddHelper: Bool {
        item.canAddHelper(members: cohabitantStore.members)
    }

    func tappedAction(_ action: HouseworkDetailAction) {
        switch action {
        case .complete:
            isPresentedCompleteSheet = true

        case .sendThanks, .addThanksMessage, .editThanksMessage:
            isPresentedThanksView = true

        case .addHelper:
            isPresentedAddHelperSheet = true

        case .redo, .returnToIncomplete, .remove:
            loadingState.task {
                await perform(action)
            }
        }
    }

    /// ハーフモーダルを挟まないアクションを実行する
    func perform(_ action: HouseworkDetailAction) async {
        guard let cohabitantId = account.cohabitantId else { return }

        do {
            switch action {
            case .redo:
                try await houseworkListStore.redo(
                    target: item.originalItem,
                    now: now,
                    executor: account,
                    cohabitantId: cohabitantId,
                    step: .detail
                )

            case .returnToIncomplete:
                try await houseworkListStore.returnToIncomplete(
                    target: item.originalItem,
                    cohabitantId: cohabitantId,
                    step: .detail
                )

            case .remove:
                try await houseworkListStore.remove(
                    target: item.originalItem,
                    cohabitantId: cohabitantId,
                    isRegistered: item.isRegistered,
                    step: .detail
                )
                // 一覧から取り下げた家事の詳細は見られても意味がないため閉じる
                dismiss()

            case .complete, .sendThanks, .addThanksMessage, .editThanksMessage, .addHelper:
                // ハーフモーダルで入力を受け取ってから実行するアクション
                break
            }
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

#Preview("HouseworkDetailView_完了") {
    NavigationStack {
        HouseworkDetailView(
            item: .makeForPreview(
                title: "洗濯",
                point: 10,
                state: .completed,
                executorId: "executorAccount",
                executedAt: .previewDate(year: 2026, month: 1, day: 1)
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
