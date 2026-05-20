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
                    .foregroundStyle(.primary2)
            }
            HouseworkDetailItemRow(title: "ステータス") {
                Text(item.state.segmentTitle)
                    .font(with: .body)
                    .foregroundStyle(.primary2)
            }
            HouseworkDetailItemRow(title: "ポイント") {
                PointLabel(point: item.point)
            }
            if let executorId = item.executorId,
               let executorUserName = cohabitantMemberList.userName(executorId) {
                HouseworkDetailItemRow(title: "実施者") {
                    Text(executorUserName)
                        .font(with: .body)
                        .foregroundStyle(.primary2)
                }
            }
        }
    }

}

#Preview("HouseworkDetailItemListContent_未完了時", traits: .sizeThatFitsLayout) {
    HouseworkDetailItemListContent(
        cohabitantMemberList: .init(value: [], ownId: ""),
        item: .makeForPreview(
            title: "洗濯",
            point: 10
        )
    )
}

#Preview("HouseworkDetailItemListContent_承認確認時", traits: .sizeThatFitsLayout) {
    HouseworkDetailItemListContent(
        cohabitantMemberList: .init(
            value: [.init(id: "test", userName: "hogehoge")],
            ownId: "test"
        ),
        item: .makeForPreview(
            title: "洗濯",
            point: 10,
            executorId: "test",
            executedAt: .distantPast
        )
    )
}
