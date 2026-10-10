//
//  HouseworkCompleteSheet.swift
//  LocalPackage
//

import HometeDomain
import HometeResources
import HometeUI
import SwiftUI

/// 家事を完了にするハーフモーダル
///
/// 頑張り度と、担当者（自分以外や複数人も選べる）・ポイントの配分を入力する。
public struct HouseworkCompleteSheet: View {

    @Environment(\.cohabitantMembers) var members
    @Environment(\.loginContext.account) var account

    let item: HouseworkBoardItem
    let step: HouseworkAnalyticsStep

    public init(item: HouseworkBoardItem, step: HouseworkAnalyticsStep) {
        self.item = item
        self.step = step
    }

    public var body: some View {
        HouseworkCompleteView(item: item, step: step, members: members, account: account)
    }

}

/// 家事を完了にするハーフモーダルの中身
struct HouseworkCompleteView: View {

    @Environment(HouseworkListStore.self) var houseworkListStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.now) var now
    @CommonError var commonError
    @LoadingState var loadingState

    let item: HouseworkBoardItem
    let step: HouseworkAnalyticsStep
    /// 担当者として選べるメンバー（メンバー一覧の並び順。自分が先頭）
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
        // メンバーの読み込み前に開かれても自分だけは選べるようにする
        selectableMembers = members.value.isEmpty
            ? [.init(id: account.id, userName: account.userName)]
            : members.value
        self.account = account
        // @Stateは他のプロパティを初期化してから代入する（iOS 27 SDKで@Stateがマクロになったため）
        self.allocation = allocation ?? .init(
            memberIds: selectableMembers.map(\.id),
            selectedIds: [account.id],
            basePoint: item.originalItem.point
        )
        self.isExpandedAllocation = isExpandedAllocation
    }

    var body: some View {
        NavigationStack {
            ContentFittingSheetScrollView {
                VStack(alignment: .leading, spacing: .space24) {
                    // 担当者に配分するポイントが頑張り度で変わるため、頑張り度を先に選ばせる
                    effortSection()
                    executorSection()
                }
                .padding(.horizontal, .space16)
                .padding(.vertical, .space24)
            }
            .navigationTitle(.localized("完了にする"))
            .inlineNavigationBarTitleDisplayMode()
            .leadingToolbarItem {
                NavigationBarButton(label: .close) {
                    dismiss()
                }
            }
            .trailingToolbarItem {
                completeButton()
            }
        }
        .presentationDragIndicator(.visible)
        .fullScreenLoadingIndicator(loadingState)
        .commonError(content: $commonError)
        .trackScreenView(.houseworkComplete)
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
            loadingState.task {
                await tappedCompleteButton()
            }
        }
        .foregroundStyle(.textOnAccent)
        .disabled(allocation.validationError != nil)
    }

}

// MARK: - プレゼンテーションロジック

extension HouseworkCompleteView {

    func userName(_ userId: String) -> String {
        selectableMembers.first { $0.id == userId }?.userName ?? ""
    }

    func tappedCompleteButton() async {
        guard let cohabitantId = account.cohabitantId else { return }

        do {
            let executors = try allocation.makeExecutors()
            try await houseworkListStore.complete(
                target: item.originalItem,
                now: now,
                reporter: account,
                executors: executors,
                effort: allocation.effort,
                executorNames: executors.map { userName($0.userId) },
                comment: "",
                cohabitantId: cohabitantId,
                isRegistered: item.isRegistered,
                step: step
            )
            dismiss()
        } catch {
            commonError = .init(error: error)
        }
    }

}

#if DEBUG
#Preview("HouseworkCompleteView_自分だけ") {
    HouseworkCompleteView(
        item: .makeForPreview(title: "洗濯", point: 10),
        step: .detail,
        members: .init(
            value: [.init(id: "own", userName: "たいち"), .init(id: "partner", userName: "はなこ")],
            ownId: "own"
        ),
        account: .init(id: "own", userName: "たいち", fcmToken: nil, cohabitantId: "cohabitant")
    )
    .environment(HouseworkListStore())
}

#Preview("HouseworkCompleteView_配分の調整を開いた状態") {
    HouseworkCompleteView(
        item: .makeForPreview(title: "洗濯", point: 10),
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
        // CohabitantMemberList.valueと同じ並び順（自分が先頭、他はユーザーID昇順）
        allocation: .init(
            memberIds: ["own", "child", "partner"],
            selectedIds: ["own", "child", "partner"],
            basePoint: 10
        ),
        isExpandedAllocation: true
    )
    .environment(HouseworkListStore())
}
#endif
