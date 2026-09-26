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
/// 担当者（自分以外や複数人も選べる）とポイントの配分を入力する。
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
            totalPoint: item.point
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
            .navigationTitle("完了にする")
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

    func executorSection() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("担当者")
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
            HouseworkExecutorSelectionContent(rows: executorRows) { userId in
                allocation.toggle(userId)
            }
            if let executorLimitMessage {
                Text(executorLimitMessage)
                    .font(with: .caption)
                    .foregroundStyle(.onSurfaceVariant)
            }
            if allocation.canAdjustPercentage {
                DisclosureGroup("配分を調整する", isExpanded: $isExpandedAllocation) {
                    HouseworkExecutorAllocationContent(
                        entries: allocationEntries,
                        totalPercentage: allocation.totalPercentage,
                        percentageRange: HouseworkExecutorAllocation.percentageRange
                    ) { userId, percentage in
                        allocation.updatePercentage(percentage, for: userId)
                    }
                    .padding(.top, .space8)
                }
                .font(with: .body)
                .tint(.onSurface)
            }
            if let validationMessage {
                Text(validationMessage)
                    .font(with: .caption)
                    .foregroundStyle(.alert)
            }
        }
    }

    func completeButton() -> some View {
        NavigationBarPrimaryActionButton(systemImage: "checkmark") {
            loadingState.task {
                await tappedCompleteButton()
            }
        }
        .foregroundStyle(.onPrimary1)
        .disabled(allocation.validationError != nil)
    }

}

// MARK: - プレゼンテーションロジック

extension HouseworkCompleteView {

    var executorRows: [HouseworkExecutorSelectionContent.Row] {
        let points = allocation.points
        return selectableMembers.map { member in
            let entryIndex = allocation.entries.firstIndex { $0.userId == member.id }
            let allocationValue = entryIndex.flatMap { index -> HouseworkExecutorSelectionContent.Allocation? in
                guard points.indices.contains(index) else { return nil }
                return .init(percentage: allocation.entries[index].percentage, point: points[index])
            }
            return .init(
                userId: member.id,
                userName: member.userName,
                isSelected: entryIndex != nil,
                isEnabled: allocation.canToggle(member.id),
                allocation: allocationValue
            )
        }
    }

    var allocationEntries: [HouseworkExecutorAllocationContent.Entry] {
        allocation.entries.map { entry in
            .init(
                userId: entry.userId,
                userName: userName(entry.userId),
                percentage: entry.percentage
            )
        }
    }

    /// 家事のポイントより多い人数は選べないことを伝える文言
    var executorLimitMessage: String? {
        let maxCount = HouseworkExecutorAllocation.maxExecutorCount(totalPoint: item.point)
        guard selectableMembers.count > maxCount else { return nil }

        return "この家事は\(item.point)ptなので、担当者は\(maxCount)人まで選べます"
    }

    var validationMessage: String? {
        switch allocation.validationError {
        case .noExecutor:
            "担当者を1人以上選んでください"

        case let .percentageNotHundred(total):
            "割合の合計が100%になるように調整してください（いまは\(total)%です）"

        case .zeroPoint:
            "全員が1pt以上になるように配分してください"

        case nil:
            nil
        }
    }

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
            totalPoint: 10
        ),
        isExpandedAllocation: true
    )
    .environment(HouseworkListStore())
}
#endif
