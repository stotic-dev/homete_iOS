//
//  HouseworkDetailItemListContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/01/04.
//

import HometeDomain
import HometeResources
import HometeUI
import SwiftUI

struct HouseworkDetailItemListContent: View {

    @Environment(\.calendar) var calendar

    let cohabitantMemberList: CohabitantMemberList
    let item: HouseworkBoardItem
    /// 家事に届いたありがとう。届いていなければ空
    var thanksMessages: [HouseworkThanksMessage] = []

    var body: some View {
        VStack(alignment: .leading, spacing: .space24) {
            HouseworkDetailItemRow(title: "実施予定日付") {
                Text(item.formattedIndexedDate(calendar: calendar))
                    .font(with: .body)
                    .foregroundStyle(.onSurfaceVariant)
            }
            HouseworkDetailItemRow(title: "ステータス") {
                Text(item.state.segmentTitle)
                    .font(with: .body)
                    .foregroundStyle(.onSurfaceVariant)
            }
            HouseworkDetailItemRow(title: "ポイント") {
                PointLabel(point: item.earnedPoint)
            }
            if let effortLabel {
                HouseworkDetailItemRow(title: "頑張り度") {
                    Text(effortLabel)
                        .font(with: .body)
                        .foregroundStyle(.onSurfaceVariant)
                }
            }
            if !executors.isEmpty {
                HouseworkDetailItemRow(title: "担当者") {
                    VStack(alignment: .leading, spacing: .space8) {
                        ForEach(executors, id: \.userId) { executor in
                            Text(executorLabel(executor))
                                .font(with: .body)
                                .foregroundStyle(.onSurfaceVariant)
                        }
                    }
                }
            }
            if !thanksMessages.isEmpty {
                HouseworkDetailItemRow(title: "ありがとう") {
                    VStack(alignment: .leading, spacing: .space16) {
                        ForEach(thanksMessages.indices, id: \.self) { index in
                            thanksMessageRow(thanksMessages[index])
                        }
                    }
                }
            }
        }
    }

}

private extension HouseworkDetailItemListContent {

    /// グループのメンバーの担当者（グループを抜けたメンバーは名前が分からないため出さない）
    var executors: [HouseworkExecutor] {
        item.executors.filter { cohabitantMemberList.userName($0.userId) != nil }
    }

    /// 完了した家事の頑張り度。上乗せしたときはポイントの内訳を添える（例: `がんばった（10pt → 12pt）`）
    var effortLabel: String? {
        guard item.state == .completed else { return nil }

        guard let pointBreakdown = item.effort.pointBreakdown(basePoint: item.originalItem.point) else {
            return item.effort.title
        }
        return "\(item.effort.title)（\(pointBreakdown)）"
    }

    /// 複数人で担当した家事は、名前に割合とポイントを添える
    func executorLabel(_ executor: HouseworkExecutor) -> String {
        let userName = cohabitantMemberList.userName(executor.userId) ?? ""
        guard item.executors.count > 1 else { return userName }

        return "\(userName) \(executor.percentage)%（\(executor.point)pt）"
    }

    func thanksMessageRow(_ thanksMessage: HouseworkThanksMessage) -> some View {
        VStack(alignment: .leading, spacing: .space4) {
            Label {
                Text("\(thanksMessage.senderName)さんから")
            } icon: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.thanksHeart)
            }
            .font(with: .boldCaption)
            .foregroundStyle(.onSubSurface)
            // メッセージを書かずに伝えたありがとうは、ハートをタップしたときの気持ちを代わりに添える
            Text(thanksMessage.comment ?? "ありがとう！")
                .font(with: .body)
                .foregroundStyle(.onSurfaceVariant)
        }
        .accessibilityElement(children: .combine)
    }

}

#if DEBUG
#Preview("HouseworkDetailItemListContent_未完了時", traits: .sizeThatFitsLayout) {
    HouseworkDetailItemListContent(
        cohabitantMemberList: .init(value: [], ownId: ""),
        item: .makeForPreview(
            title: "洗濯",
            point: 10
        )
    )
    .setupEnvironmentForPreview()
}

#Preview("HouseworkDetailItemListContent_完了時", traits: .sizeThatFitsLayout) {
    HouseworkDetailItemListContent(
        cohabitantMemberList: .init(
            value: [.init(id: "test", userName: "hogehoge")],
            ownId: "test"
        ),
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            state: .completed,
            executorId: "test",
            executedAt: .distantPast
        )
    )
    .setupEnvironmentForPreview()
}

#Preview("HouseworkDetailItemListContent_複数人で担当", traits: .sizeThatFitsLayout) {
    HouseworkDetailItemListContent(
        cohabitantMemberList: .init(
            value: [.init(id: "own", userName: "たいち"), .init(id: "partner", userName: "はなこ")],
            ownId: "own"
        ),
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            state: .completed,
            executors: [
                .init(userId: "own", percentage: 60, point: 6),
                .init(userId: "partner", percentage: 40, point: 4),
            ],
            executedAt: .distantPast
        )
    )
    .setupEnvironmentForPreview()
}

#Preview("HouseworkDetailItemListContent_ありがとうあり", traits: .sizeThatFitsLayout) {
    HouseworkDetailItemListContent(
        cohabitantMemberList: .init(
            value: [.init(id: "own", userName: "たいち"), .init(id: "partner", userName: "はなこ")],
            ownId: "own"
        ),
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            state: .completed,
            executorId: "own",
            executedAt: .distantPast
        ),
        thanksMessages: [
            .init(senderName: "はなこ", comment: "いつも洗濯してくれてありがとう！助かっています。"),
            .init(senderName: "じろう", comment: nil),
        ]
    )
    .setupEnvironmentForPreview()
}

#Preview("HouseworkDetailItemListContent_がんばった", traits: .sizeThatFitsLayout) {
    HouseworkDetailItemListContent(
        cohabitantMemberList: .init(
            value: [.init(id: "test", userName: "hogehoge")],
            ownId: "test"
        ),
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            state: .completed,
            executorId: "test",
            effort: .hard,
            executedAt: .distantPast
        )
    )
    .setupEnvironmentForPreview()
}
#endif
