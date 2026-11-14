//
//  HouseworkAddHelperView.swift
//  LocalPackage
//

import HometeModel
import HometeResources
import HometeUI
import SwiftUI

/// 完了した家事に手伝った人を追加するハーフモーダルの中身
/// - Note: 保存は`HouseworkAddHelperSheet`が受け持つ。`NavigationStack`の中に置かれる前提でツールバーの項目を並べる
public struct HouseworkAddHelperView: View {

    let item: HouseworkBoardItem
    /// 担当者として選べるメンバー（メンバー一覧の並び順。自分が先頭）
    ///
    /// メンバーの読み込み前に開かれた場合は空になり、配分が確定できないため保存できない。
    /// この画面への導線は、足せるメンバーがいるときだけ出す。
    let selectableMembers: [CohabitantMember]
    let onTapClose: () -> Void
    /// 決めた配分で保存する
    let onTapSave: (HouseworkExecutorAllocation) -> Void

    @State var allocation: HouseworkExecutorAllocation
    @State var isExpandedAllocation: Bool

    public init(
        item: HouseworkBoardItem,
        members: CohabitantMemberList,
        allocation: HouseworkExecutorAllocation? = nil,
        isExpandedAllocation: Bool = false,
        onTapClose: @escaping () -> Void,
        onTapSave: @escaping (HouseworkExecutorAllocation) -> Void
    ) {
        self.item = item
        selectableMembers = members.value
        self.onTapClose = onTapClose
        self.onTapSave = onTapSave
        // @Stateは他のプロパティを初期化してから代入する（iOS 27 SDKで@Stateがマクロになったため）
        self.allocation = allocation ?? .forAddingExecutors(
            memberIds: members.value.map(\.id),
            executors: item.executors,
            earnedPoint: item.earnedPoint
        )
        self.isExpandedAllocation = isExpandedAllocation
    }

    public var body: some View {
        ContentFittingSheetScrollView {
            executorSection()
                .padding(.horizontal, .space16)
                .padding(.vertical, .space24)
        }
        .navigationTitle(.localized("手伝った人を追加"))
        .inlineNavigationBarTitleDisplayMode()
        .leadingToolbarItem {
            NavigationBarButton(label: .close) {
                onTapClose()
            }
        }
        .trailingToolbarItem {
            saveButton()
        }
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
            onTapSave(allocation)
        }
        .foregroundStyle(.textOnAccent)
        .disabled(!canSave)
    }

    /// 保存できるかどうか
    ///
    /// 配分が確定できることに加えて、保存済みの担当者から変わっていることを条件にする。
    /// 開いて保存しただけで書き込みとAnalyticsのイベントが発生すると、「後から手伝った人を足した」
    /// 件数を数えられなくなるため。
    var canSave: Bool {
        guard let executors = try? allocation.makeExecutors() else { return false }

        return executors != item.executors
    }

}

#if DEBUG
#Preview("HouseworkAddHelperView_担当者が1人") {
    NavigationStack {
        HouseworkAddHelperView(
            item: .makeForPreview(
                title: "洗濯",
                point: 10,
                state: .completed,
                executorId: "own"
            ),
            members: .init(
                value: [.init(id: "own", userName: "たいち"), .init(id: "partner", userName: "はなこ")],
                ownId: "own"
            ),
            onTapClose: {},
            onTapSave: { _ in }
        )
    }
}

#Preview("HouseworkAddHelperView_配分の調整を開いた状態") {
    NavigationStack {
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
            members: .init(
                value: [
                    .init(id: "own", userName: "たいち"),
                    .init(id: "partner", userName: "はなこ"),
                    .init(id: "child", userName: "じろう"),
                ],
                ownId: "own"
            ),
            isExpandedAllocation: true,
            onTapClose: {},
            onTapSave: { _ in }
        )
    }
}
#endif
