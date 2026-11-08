//
//  HouseworkDetailView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/08.
//

import HometeModel
import HometeUI
import SwiftUI

/// 家事の詳細画面
/// - Note: 操作・シート・メモの保存は`HouseworkDetailScreen`が受け持ち、画像の欄を差し込む
public struct HouseworkDetailView<ImageSection: View>: View {

    let item: HouseworkBoardItem
    let cohabitantMemberList: CohabitantMemberList
    /// ナビゲーションバーに単独のボタンとして出すアクション
    let primaryAction: HouseworkDetailAction?
    /// 「その他」のメニューに入れるアクション
    let menuActions: [HouseworkDetailAction]
    /// チェックの保存中か
    let isSavingMemoCheck: Bool
    /// 通信中か。通信中はアクションを押せなくする
    let isLoading: Bool
    let onTapAction: (HouseworkDetailAction) -> Void
    let onTapEditMemo: () -> Void
    let onToggleMemoChecklistItem: (HouseworkMemoChecklistItem.ID) -> Void
    @ViewBuilder let imageSection: () -> ImageSection

    public init(
        item: HouseworkBoardItem,
        cohabitantMemberList: CohabitantMemberList,
        primaryAction: HouseworkDetailAction?,
        menuActions: [HouseworkDetailAction],
        isSavingMemoCheck: Bool = false,
        isLoading: Bool = false,
        onTapAction: @escaping (HouseworkDetailAction) -> Void,
        onTapEditMemo: @escaping () -> Void,
        onToggleMemoChecklistItem: @escaping (HouseworkMemoChecklistItem.ID) -> Void,
        @ViewBuilder imageSection: @escaping () -> ImageSection
    ) {
        self.item = item
        self.cohabitantMemberList = cohabitantMemberList
        self.primaryAction = primaryAction
        self.menuActions = menuActions
        self.isSavingMemoCheck = isSavingMemoCheck
        self.isLoading = isLoading
        self.onTapAction = onTapAction
        self.onTapEditMemo = onTapEditMemo
        self.onToggleMemoChecklistItem = onToggleMemoChecklistItem
        self.imageSection = imageSection
    }

    public var body: some View {
        mainContent()
            .navigationTitle(item.title)
            .inlineNavigationBarTitleDisplayMode()
            .trailingToolbarItem {
                HouseworkDetailActionContent(
                    primaryAction: primaryAction,
                    menuActions: menuActions,
                    onTap: onTapAction
                )
                .disabled(isLoading)
            }
    }

}

private extension HouseworkDetailView {

    func mainContent() -> some View {
        ScrollView {
            VStack(spacing: .space24) {
                HouseworkDetailItemListContent(
                    cohabitantMemberList: cohabitantMemberList,
                    item: item,
                    thanksMessages: HouseworkThanksMessage.make(item: item, memberList: cohabitantMemberList)
                )
                if isMemoVisible {
                    HouseworkDetailMemoContent(
                        memo: item.originalItem.memo.hasContent ? item.originalItem.memo : nil,
                        isEditable: item.originalItem.canEditMemo,
                        isUpdating: isSavingMemoCheck,
                        onTapEdit: onTapEditMemo,
                        onToggle: onToggleMemoChecklistItem
                    )
                }
                if isImageSectionVisible {
                    imageSection()
                }
            }
            .padding(.horizontal, .space16)
            .padding(.vertical, .space24)
        }
        .scrollBounceBehavior(.basedOnSize)
        // 家事ボードからの遷移で地の色が変わらないよう、ボードと同じミルク色にして白いカードを浮かせる
        .background(.backgroundScreen)
        .softTopScrollEdgeEffect()
    }

}

// MARK: 表示内容

private extension HouseworkDetailView {

    /// メモ欄を出すか。完了済み・「やらない」の家事は、メモがあるときだけ閲覧用に出す
    var isMemoVisible: Bool {
        item.originalItem.canEditMemo || item.originalItem.memo.hasContent
    }

    /// 画像の欄を出すか。完了済み・「やらない」の家事は、画像があるときだけ閲覧用に出す（メモと同じ）
    var isImageSectionVisible: Bool {
        item.originalItem.canAddImages || item.originalItem.images.hasContent
    }

}

#if DEBUG
#Preview {
    let item = HouseworkBoardItem.makeForPreview(
        title: "洗濯",
        point: 10
    )
    let members = CohabitantMemberList(value: [], ownId: "")
    let actions = HouseworkDetailAction.actions(
        for: item,
        ownUserId: "",
        canAddHelper: item.canAddHelper(members: members)
    )
    NavigationStack {
        HouseworkDetailView(
            item: item,
            cohabitantMemberList: members,
            primaryAction: actions.first(where: \.isPrimary),
            menuActions: actions.filter { !$0.isPrimary },
            onTapAction: { _ in },
            onTapEditMemo: {},
            onToggleMemoChecklistItem: { _ in },
            imageSection: { EmptyView() }
        )
    }
    .setupEnvironmentForPreview()
}

#Preview("HouseworkDetailView_メモあり") {
    let item = HouseworkBoardItem.makeForPreview(
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
    let members = CohabitantMemberList(value: [], ownId: "")
    let actions = HouseworkDetailAction.actions(
        for: item,
        ownUserId: "",
        canAddHelper: item.canAddHelper(members: members)
    )
    NavigationStack {
        HouseworkDetailView(
            item: item,
            cohabitantMemberList: members,
            primaryAction: actions.first(where: \.isPrimary),
            menuActions: actions.filter { !$0.isPrimary },
            onTapAction: { _ in },
            onTapEditMemo: {},
            onToggleMemoChecklistItem: { _ in },
            imageSection: { EmptyView() }
        )
    }
    .setupEnvironmentForPreview()
}

#Preview("HouseworkDetailView_完了") {
    let item = HouseworkBoardItem.makeForPreview(
        title: "洗濯",
        point: 10,
        state: .completed,
        executorId: "executorAccount",
        executedAt: .previewDate(year: 2026, month: 1, day: 1)
    )
    let members = CohabitantMemberList(value: [], ownId: "")
    let actions = HouseworkDetailAction.actions(
        for: item,
        ownUserId: "",
        canAddHelper: item.canAddHelper(members: members)
    )
    NavigationStack {
        HouseworkDetailView(
            item: item,
            cohabitantMemberList: members,
            primaryAction: actions.first(where: \.isPrimary),
            menuActions: actions.filter { !$0.isPrimary },
            onTapAction: { _ in },
            onTapEditMemo: {},
            onToggleMemoChecklistItem: { _ in },
            imageSection: { EmptyView() }
        )
    }
    .setupEnvironmentForPreview()
}

// スピナーは撮影ごとに回転角が変わりVRTがフレーキーになるため、スナップショットの対象から外す
#Preview("HouseworkDetailView_通信中") {
    NavigationStack {
        HouseworkDetailView(
            item: .makeForPreview(title: "洗濯", point: 10),
            cohabitantMemberList: .init(value: [], ownId: ""),
            primaryAction: .complete,
            menuActions: [],
            isLoading: true,
            onTapAction: { _ in },
            onTapEditMemo: {},
            onToggleMemoChecklistItem: { _ in },
            imageSection: { EmptyView() }
        )
    }
    .setupEnvironmentForPreview()
    #if canImport(Prefire)
        .prefireIgnored()
    #endif
}
#endif
