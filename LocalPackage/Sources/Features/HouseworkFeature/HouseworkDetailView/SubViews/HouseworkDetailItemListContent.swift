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
                PointLabel(point: item.point)
            }
            if let executorId = item.executorId,
               let executorUserName = cohabitantMemberList.userName(executorId) {
                HouseworkDetailItemRow(title: "実施者") {
                    Text(executorUserName)
                        .font(with: .body)
                        .foregroundStyle(.onSurfaceVariant)
                }
            }
            if !item.originalItem.thanks.isEmpty {
                HouseworkDetailItemRow(title: "もらったありがとう") {
                    VStack(spacing: .space8) {
                        ForEach(item.originalItem.thanks, id: \.self) { thanks in
                            HouseworkDetailThanksCard(
                                senderName: senderName(of: thanks),
                                comment: thanks.comment
                            )
                        }
                    }
                }
            }
        }
    }

}

private extension HouseworkDetailItemListContent {

    /// 送った人がグループを抜けていて名前が引けない場合も、ありがとうが届いた事実は残して見せる
    func senderName(of thanks: HouseworkThanks) -> String {
        cohabitantMemberList.userName(thanks.senderId) ?? "同居人"
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

#Preview("HouseworkDetailItemListContent_ありがとう受け取り時", traits: .sizeThatFitsLayout) {
    HouseworkDetailItemListContent(
        cohabitantMemberList: .init(
            value: [
                .init(id: "executor", userName: "hogehoge"),
                .init(id: "sender", userName: "fugafuga"),
            ],
            ownId: "executor"
        ),
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            state: .completed,
            executorId: "executor",
            executedAt: .distantPast,
            thanks: [
                .init(senderId: "sender", comment: "いつもありがとう！", sentAt: .distantPast),
                .init(senderId: "leftMember", comment: "助かりました", sentAt: .distantPast),
            ]
        )
    )
    .setupEnvironmentForPreview()
}
#endif
