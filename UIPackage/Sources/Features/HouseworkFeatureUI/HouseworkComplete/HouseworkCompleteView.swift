//
//  HouseworkCompleteView.swift
//  LocalPackage
//

import HometeModel
import HometeResources
import HometeUI
import SwiftUI

/// 家事を完了にするハーフモーダルの中身
/// - Note: 完了にする処理は`HouseworkCompleteSheet`が受け持つ。`NavigationStack`の中に置かれる前提でツールバーの項目を並べる
public struct HouseworkCompleteView: View {

    let item: HouseworkBoardItem
    /// 担当者として選べるメンバー（メンバー一覧の並び順。自分が先頭）
    let selectableMembers: [CohabitantMember]
    /// 完了にできたときの、ほめっとがほめる内容。入ると中身を演出に切り替える
    let praise: HometteCompletionPraise?
    let onTapClose: () -> Void
    /// 決めた頑張り度と配分で完了にする
    let onTapComplete: (HouseworkExecutorAllocation) -> Void
    /// ほめる演出を見せ終わった
    let onFinishPraise: () -> Void

    @State var allocation: HouseworkExecutorAllocation
    @State var isExpandedAllocation: Bool

    public init(
        item: HouseworkBoardItem,
        members: CohabitantMemberList,
        account: Account,
        praise: HometteCompletionPraise? = nil,
        allocation: HouseworkExecutorAllocation? = nil,
        isExpandedAllocation: Bool = false,
        onTapClose: @escaping () -> Void,
        onTapComplete: @escaping (HouseworkExecutorAllocation) -> Void,
        onFinishPraise: @escaping () -> Void
    ) {
        self.item = item
        self.praise = praise
        self.onTapClose = onTapClose
        self.onTapComplete = onTapComplete
        self.onFinishPraise = onFinishPraise
        // メンバーの読み込み前に開かれても自分だけは選べるようにする
        selectableMembers = members.value.isEmpty
            ? [.init(id: account.id, userName: account.userName)]
            : members.value
        // @Stateは他のプロパティを初期化してから代入する（iOS 27 SDKで@Stateがマクロになったため）
        self.allocation = allocation ?? .init(
            memberIds: selectableMembers.map(\.id),
            selectedIds: [account.id],
            basePoint: item.originalItem.point
        )
        self.isExpandedAllocation = isExpandedAllocation
    }

    public var body: some View {
        // 演出に切り替えてもシートの高さを中身に合わせ続けるため、中身だけを差し替える
        ContentFittingSheetScrollView {
            if let praise {
                HometteCompletionPraisePlayer(praise: praise) {
                    onFinishPraise()
                }
                .padding(.horizontal, .space16)
                .padding(.vertical, .space24)
            } else {
                VStack(alignment: .leading, spacing: .space24) {
                    // 担当者に配分するポイントが頑張り度で変わるため、頑張り度を先に選ばせる
                    effortSection()
                    executorSection()
                }
                .padding(.horizontal, .space16)
                .padding(.vertical, .space24)
            }
        }
        .navigationTitle(.localized("完了にする"))
        .inlineNavigationBarTitleDisplayMode()
        .leadingToolbarItem {
            // 完了にした後は、演出を見せ終わると自動で閉じるので、ボタンは出さない
            if praise == nil {
                NavigationBarButton(label: .close) {
                    onTapClose()
                }
            }
        }
        .trailingToolbarItem {
            if praise == nil {
                completeButton()
            }
        }
    }

}

// MARK: - UI定義

private extension HouseworkCompleteView {

    func effortSection() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            HStack(spacing: .space4) {
                Text("どれくらいがんばりましたか", bundle: #bundle)
                    .font(with: .headLineS)
                    .foregroundStyle(.textPrimary)
                DescriptionPopoverButton(
                    title: .localized("がんばりについて"),
                    message: .localized("""
                    いつもより手間をかけたときに選ぶと、もらえるポイントが増えます。
                    「がんばった」は1.2倍、「すごくがんばった」は1.5倍になります（端数は切り上げ）。
                    """)
                )
            }
            HouseworkEffortSelectionContent(
                selection: allocation.effort,
                pointBreakdown: allocation.effort.pointBreakdown(basePoint: allocation.basePoint)
            ) { effort in
                allocation.updateEffort(effort)
            }
        }
    }

    func executorSection() -> some View {
        HouseworkExecutorSectionContent(
            selectableMembers: selectableMembers,
            caption: nil,
            allocation: $allocation,
            isExpandedAllocation: $isExpandedAllocation
        )
    }

    func completeButton() -> some View {
        NavigationBarPrimaryActionButton(systemImage: "checkmark") {
            onTapComplete(allocation)
        }
        .foregroundStyle(.textOnAccent)
        .disabled(allocation.validationError != nil)
    }

}

#if DEBUG
#Preview("HouseworkCompleteView_自分だけ") {
    NavigationStack {
        HouseworkCompleteView(
            item: .makeForPreview(title: "洗濯", point: 10),
            members: .init(
                value: [.init(id: "own", userName: "たいち"), .init(id: "partner", userName: "はなこ")],
                ownId: "own"
            ),
            account: .init(id: "own", userName: "たいち", cohabitantId: "cohabitant"),
            onTapClose: {},
            onTapComplete: { _ in },
            onFinishPraise: {}
        )
    }
}

#Preview("HouseworkCompleteView_配分の調整を開いた状態") {
    NavigationStack {
        HouseworkCompleteView(
            item: .makeForPreview(title: "洗濯", point: 10),
            members: .init(
                value: [
                    .init(id: "own", userName: "たいち"),
                    .init(id: "partner", userName: "はなこ"),
                    .init(id: "child", userName: "じろう"),
                ],
                ownId: "own"
            ),
            account: .init(id: "own", userName: "たいち", cohabitantId: "cohabitant"),
            // CohabitantMemberList.valueと同じ並び順（自分が先頭、他はユーザーID昇順）
            allocation: .init(
                memberIds: ["own", "child", "partner"],
                selectedIds: ["own", "child", "partner"],
                basePoint: 10
            ),
            isExpandedAllocation: true,
            onTapClose: {},
            onTapComplete: { _ in },
            onFinishPraise: {}
        )
    }
}
#endif
