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
    @State var isPresentedMemoEditSheet = false
    @State var isPresentedMemoNotEditableAlert = false
    /// チェックの保存中か
    /// - Note: 保存がリスナーに反映される前に次のチェックを保存すると、古いメモを元に書いて先のチェックを消すため、1つずつ保存する
    @State var isSavingMemoCheck = false

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
            .sheet(isPresented: $isPresentedMemoEditSheet) {
                HouseworkMemoEditScreen(memo: item.originalItem.memo) { memo in
                    savedMemo(memo)
                }
            }
            .alert("メモを保存できませんでした", isPresented: $isPresentedMemoNotEditableAlert) {
                Button("閉じる", role: .cancel) {}
            } message: {
                Text("この家事は完了または「やらない」になったため、メモを編集できません。")
            }
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
                if isMemoVisible {
                    HouseworkDetailMemoContent(
                        memo: item.originalItem.memo.hasContent ? item.originalItem.memo : nil,
                        isEditable: item.originalItem.canEditMemo && !isSavingMemoCheck,
                        onTapEdit: { isPresentedMemoEditSheet = true },
                        onToggle: { checklistItemId in tappedMemoChecklistItem(checklistItemId) }
                    )
                }
                HouseworkDetailActionContent(
                    isLoading: $loadingState.isLoading,
                    commonErrorContent: $commonErrorContent,
                    account: account,
                    item: item
                )
            }
            .padding(.horizontal, .space16)
            .padding(.bottom, .space24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .softTopScrollEdgeEffect()
    }

}

// MARK: 表示内容

private extension HouseworkDetailView {

    /// メモ欄を出すか。完了済み・「やらない」の家事は、メモがあるときだけ閲覧用に出す
    var isMemoVisible: Bool {
        item.originalItem.canEditMemo || item.originalItem.memo.hasContent
    }

}

// MARK: プレゼンテーションロジック

private extension HouseworkDetailView {

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

    func savedMemo(_ memo: HouseworkMemo) {
        guard let cohabitantId = account.cohabitantId else { return }

        let target = item
        loadingState.task {
            do {
                try await houseworkListStore.updateMemo(
                    target: target.originalItem,
                    memo: memo,
                    cohabitantId: cohabitantId,
                    isRegistered: target.isRegistered,
                    step: .detail
                )
            } catch {
                handleMemoError(error)
            }
        }
    }

    func tappedMemoChecklistItem(_ checklistItemId: HouseworkMemoChecklistItem.ID) {
        guard let cohabitantId = account.cohabitantId,
              let memo = item.originalItem.memo,
              item.originalItem.canEditMemo,
              !isSavingMemoCheck else { return }

        let target = item
        // 保存を待たずにチェックを反映し、失敗したら元に戻す
        item = .init(
            originalItem: target.originalItem.updateMemo(memo.toggled(checklistItemId)),
            isRegistered: target.isRegistered
        )
        isSavingMemoCheck = true
        Task {
            defer { isSavingMemoCheck = false }
            do {
                try await houseworkListStore.toggleMemoChecklistItem(
                    target: target.originalItem,
                    itemId: checklistItemId,
                    cohabitantId: cohabitantId,
                    isRegistered: target.isRegistered
                )
            } catch {
                item = houseworkListStore.items.item(target.originalItem)
                    .map { .init(originalItem: $0, isRegistered: true) } ?? target
                handleMemoError(error)
            }
        }
    }

    func handleMemoError(_ error: any Error) {
        if error as? HouseworkMemoError == .notEditable {
            isPresentedMemoNotEditableAlert = true
        } else {
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

#Preview("HouseworkDetailView_メモあり") {
    NavigationStack {
        HouseworkDetailView(
            item: .makeForPreview(
                title: "買い出し",
                point: 10,
                memo: .init(
                    text: "駅前のスーパーで",
                    checklist: [
                        .init(id: "1", title: "牛乳", isChecked: true),
                        .init(id: "2", title: "卵", isChecked: false),
                    ]
                )
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
