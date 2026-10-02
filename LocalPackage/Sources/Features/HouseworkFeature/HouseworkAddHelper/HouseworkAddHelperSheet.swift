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
public struct HouseworkAddHelperSheet: View {

    @Environment(\.cohabitantMembers) var members
    @Environment(\.loginContext.account) var account

    let item: HouseworkBoardItem
    let step: HouseworkAnalyticsStep

    public init(item: HouseworkBoardItem, step: HouseworkAnalyticsStep) {
        self.item = item
        self.step = step
    }

    public var body: some View {
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
            .navigationTitle("手伝った人を追加")
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
        VStack(alignment: .leading, spacing: .space8) {
            Text("担当者")
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
            Text("手伝ってくれた人を選ぶと、この家事のポイントを分け合えます。もともとの担当者は外せません。")
                .font(with: .caption)
                .foregroundStyle(.onSurfaceVariant)
            HouseworkExecutorSelectionContent(rows: executorRows) { userId in
                allocation.toggle(userId)
            }
            if let executorLimitMessage {
                Text(executorLimitMessage)
                    .font(with: .caption)
                    .foregroundStyle(.onSurfaceVariant)
            }
            if allocation.canAdjustPercentage {
                DisclosureGroup(isExpanded: $isExpandedAllocation) {
                    HouseworkExecutorAllocationContent(
                        entries: allocationEntries,
                        percentageRange: HouseworkExecutorAllocation.percentageRange
                    ) { userId, percentage in
                        allocation.updatePercentage(percentage, for: userId)
                    }
                    .padding(.top, .space8)
                } label: {
                    HStack(spacing: .space4) {
                        Text("配分を調整する")
                        DescriptionPopoverButton(
                            title: "配分の調整とは？",
                            message: """
                            手分けした家事のポイントを、それぞれがやった割合に合わせて分けられます。
                            割合の合計が100%になるように調整してください。
                            """
                        )
                    }
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

    func saveButton() -> some View {
        NavigationBarPrimaryActionButton(systemImage: "checkmark") {
            loadingState.task {
                await tappedSaveButton()
            }
        }
        .foregroundStyle(.onPrimary1)
        .disabled(allocation.validationError != nil)
    }

}

// MARK: - プレゼンテーションロジック

extension HouseworkAddHelperView {

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
    ///
    /// 配り直す対象は頑張り度で上乗せした後のポイントなので、上限もそのポイントで決まる。
    var executorLimitMessage: String? {
        guard selectableMembers.count > allocation.maxExecutorCount else { return nil }

        return "この家事は\(item.earnedPoint)ptなので、担当者は\(allocation.maxExecutorCount)人まで選べます"
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
