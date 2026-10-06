//
//  HouseworkExecutorSectionContent.swift
//  LocalPackage
//

import HometeDomain
import HometeResources
import HometeUI
import SwiftUI

/// 家事の担当者を選び、ポイントの配分を調整するセクション
///
/// 家事を完了にするときと、完了済みの家事に手伝った人を足すときで共通の部分。
/// 何を配るか（上限の基準になるポイント）と誰を外せないかは`allocation`に入っているので、
/// 呼び出し側はそれを作って渡すだけでよい。
///
/// 選べるか・確定できるかの判定は`HouseworkExecutorAllocation`が持ち、このViewは行の表示値と文言への
/// 写像だけを行う。呼び出し側へ判定を戻すと、両画面で同じ組み立てが重複するため。
struct HouseworkExecutorSectionContent: View {

    /// 担当者として選べるメンバー（メンバー一覧の並び順。自分が先頭）
    let selectableMembers: [CohabitantMember]
    /// 見出しの下に出す説明
    let caption: String?
    @Binding var allocation: HouseworkExecutorAllocation
    @Binding var isExpandedAllocation: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("担当者")
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
            if let caption {
                Text(caption)
                    .font(with: .caption)
                    .foregroundStyle(.onSurfaceVariant)
            }
            HouseworkExecutorSelectionContent(rows: executorRows) { userId in
                allocation.toggle(userId)
            }
            if let executorLimitMessage {
                Text(executorLimitMessage)
                    .font(with: .caption)
                    .foregroundStyle(.onSurfaceVariant)
            }
            if allocation.canAdjustPercentage {
                allocationDisclosure()
            }
            if let validationMessage {
                Text(validationMessage)
                    .font(with: .caption)
                    .foregroundStyle(.alert)
            }
        }
    }

}

// MARK: - UI定義

private extension HouseworkExecutorSectionContent {

    func allocationDisclosure() -> some View {
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

}

// MARK: - プレゼンテーションロジック

extension HouseworkExecutorSectionContent {

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
                isLocked: allocation.lockedIds.contains(member.id),
                allocation: allocationValue
            )
        }
    }

    var allocationEntries: [HouseworkExecutorAllocationContent.Entry] {
        allocation.entries.map { entry in
            .init(
                userId: entry.userId,
                userName: selectableMembers.first { $0.id == entry.userId }?.userName ?? "",
                percentage: entry.percentage
            )
        }
    }

    /// 家事のポイントより多い人数は選べないことを伝える文言
    ///
    /// 上限の基準は完了時なら上乗せ前、手伝った人の追加時なら上乗せ後のポイントで、
    /// どちらも`allocation.basePoint`に入っている。
    var executorLimitMessage: String? {
        guard selectableMembers.count > allocation.maxExecutorCount else { return nil }

        return "この家事は\(allocation.basePoint)ptなので、担当者は\(allocation.maxExecutorCount)人まで選べます"
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

}

#if DEBUG
#Preview("HouseworkExecutorSectionContent_人数の上限と0ptの担当者", traits: .sizeThatFitsLayout) {
    // 2ptの家事に3人のメンバー。99%と1%に配分して、片方が0ptになった状態
    @Previewable @State var allocation: HouseworkExecutorAllocation = {
        var allocation = HouseworkExecutorAllocation.forAddingExecutors(
            memberIds: ["own", "child", "partner"],
            executors: [
                .init(userId: "own", percentage: 50, point: 1),
                .init(userId: "partner", percentage: 50, point: 1),
            ],
            earnedPoint: 2
        )
        allocation.updatePercentage(99, for: "own")
        return allocation
    }()
    @Previewable @State var isExpandedAllocation = true
    HouseworkExecutorSectionContent(
        selectableMembers: [
            .init(id: "own", userName: "たいち"),
            .init(id: "child", userName: "じろう"),
            .init(id: "partner", userName: "はなこ"),
        ],
        caption: "手伝ってくれた人を選ぶと、この家事のポイントを分け合えます。もともとの担当者は外せません。",
        allocation: $allocation,
        isExpandedAllocation: $isExpandedAllocation
    )
    .padding()
}
#endif
