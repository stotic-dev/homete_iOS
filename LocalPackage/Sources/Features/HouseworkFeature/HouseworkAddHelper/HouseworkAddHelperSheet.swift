//
//  HouseworkAddHelperSheet.swift
//  LocalPackage
//

import HometeDomain
import HometeResources
import HometeUI
import SwiftUI

/// 完了した家事に手伝った人を追加するハーフモーダル
///
/// もともとの担当者はそのままにして、手伝ってくれたメンバーを足す。家事の合計ポイントは変えず、
/// 追加後の担当者で配り直す。
struct HouseworkAddHelperSheet: View {

    @Environment(\.cohabitantMembers) var members
    @Environment(\.loginContext.account) var account

    let item: HouseworkBoardItem
    let step: HouseworkAnalyticsStep

    var body: some View {
        HouseworkAddHelperView(item: item, step: step, members: members, account: account)
    }

}

/// 完了した家事に手伝った人を追加するハーフモーダルの中身
struct HouseworkAddHelperView: View {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.dismiss) var dismiss
    @CommonError var commonError
    @LoadingState var loadingState

    let item: HouseworkBoardItem
    let step: HouseworkAnalyticsStep
    /// 担当者として選べるメンバー（メンバー一覧の並び順。自分が先頭）
    ///
    /// メンバーの読み込み前に開かれた場合は空になり、配分が確定できないため保存できない。
    /// この画面への導線は、足せるメンバーがいるときだけ出す。
    let selectableMembers: [CohabitantMember]
    let account: Account

    @State var allocation: HouseworkExecutorAllocation
    @State var isExpandedAllocation: Bool

    init(
        item: HouseworkBoardItem,
        step: HouseworkAnalyticsStep,
        members: CohabitantMemberList,
        account: Account,
        allocation: HouseworkExecutorAllocation? = nil,
        isExpandedAllocation: Bool = false
    ) {
        self.item = item
        self.step = step
        selectableMembers = members.value
        self.account = account
        // @Stateは他のプロパティを初期化してから代入する（iOS 27 SDKで@Stateがマクロになったため）
        self.allocation = allocation ?? .forAddingExecutors(
            memberIds: members.value.map(\.id),
            executors: item.executors,
            earnedPoint: item.earnedPoint
        )
        self.isExpandedAllocation = isExpandedAllocation
    }

    var body: some View {
        NavigationStack {
            ContentFittingSheetScrollView {
                executorSection()
                    .padding(.horizontal, .space16)
                    .padding(.vertical, .space24)
            }
            .navigationTitle(.localized("手伝った人を追加"))
            .inlineNavigationBarTitleDisplayMode()
            .leadingToolbarItem {
                NavigationBarButton(label: .close) {
                    dismiss()
                }
            }
            .trailingToolbarItem {
                saveButton()
            }
        }
        .presentationDragIndicator(.visible)
        .fullScreenLoadingIndicator(loadingState)
        .commonError(content: $commonError)
        .trackScreenView(.houseworkAddHelper)
    }

}

// MARK: - UI定義

private extension HouseworkAddHelperView {

    func executorSection() -> some View {
        HouseworkExecutorSectionContent(
            selectableMembers: selectableMembers,
            caption: .localized("手伝ってくれた人を選ぶと、この家事のポイントを分け合えます。もともとの担当者は外せません。"),
            allocation: $allocation,
            isExpandedAllocation: $isExpandedAllocation
        )
    }

    func saveButton() -> some View {
        NavigationBarPrimaryActionButton(systemImage: "checkmark") {
            loadingState.task {
                await tappedSaveButton()
            }
        }
        .foregroundStyle(.textOnAccent)
        .disabled(!canSave)
    }

}

// MARK: - プレゼンテーションロジック

extension HouseworkAddHelperView {

    /// 保存できるかどうか
    ///
    /// 配分が確定できることに加えて、保存済みの担当者から変わっていることを条件にする。
    /// 開いて保存しただけで書き込みとAnalyticsのイベントが発生すると、「後から手伝った人を足した」
    /// 件数を数えられなくなるため。
    var canSave: Bool {
        guard let executors = try? allocation.makeExecutors() else { return false }

        return executors != item.executors
    }

    func tappedSaveButton() async {
        guard let cohabitantId = account.cohabitantId else { return }

        do {
            let executors = try allocation.makeExecutors()
            try await houseworkListStore.addHelpers(
                target: item.originalItem,
                executors: executors,
                cohabitantId: cohabitantId,
                step: step
            )
            dismiss()
        } catch {
            commonError = .init(error: error)
        }
    }

}

#if DEBUG
#Preview("HouseworkAddHelperView_担当者が1人") {
    HouseworkAddHelperView(
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            state: .completed,
            executorId: "own"
        ),
        step: .detail,
        members: .init(
            value: [.init(id: "own", userName: "たいち"), .init(id: "partner", userName: "はなこ")],
            ownId: "own"
        ),
        account: .init(id: "own", userName: "たいち", fcmToken: nil, cohabitantId: "cohabitant")
    )
    .environment(HouseworkListStore())
}

#Preview("HouseworkAddHelperView_配分の調整を開いた状態") {
    HouseworkAddHelperView(
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            state: .completed,
            executors: [
                .init(userId: "own", percentage: 50, point: 5),
                .init(userId: "partner", percentage: 50, point: 5),
            ]
        ),
        step: .detail,
        members: .init(
            value: [
                .init(id: "own", userName: "たいち"),
                .init(id: "partner", userName: "はなこ"),
                .init(id: "child", userName: "じろう"),
            ],
            ownId: "own"
        ),
        account: .init(id: "own", userName: "たいち", fcmToken: nil, cohabitantId: "cohabitant"),
        isExpandedAllocation: true
    )
    .environment(HouseworkListStore())
}
#endif
