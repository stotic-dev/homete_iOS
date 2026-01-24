//
//  HouseworkDetailItemListContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/01/04.
//

import SwiftUI

struct HouseworkDetailItemListContent: View {
    
    let cohabitantMemberList: CohabitantMemberList
    let item: HouseworkItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: .space24) {
            HouseworkDetailItemRow(title: "実施予定日付") {
                Text(item.formattedIndexedDate)
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
        cohabitantMemberList: .init(value: []),
        item: .init(
            id: "",
            title: "洗濯",
            point: 10,
            metaData: .init(indexedDate: .init(value: "2026/1/1"), expiredAt: .distantFuture)
        )
    )
}

#Preview("HouseworkDetailItemListContent_承認確認時", traits: .sizeThatFitsLayout) {
    HouseworkDetailItemListContent(
        cohabitantMemberList: .init(value: [.init(id: "test", userName: "hogehoge")]),
        item: .init(
            id: "",
            title: "洗濯",
            point: 10,
            metaData: .init(indexedDate: .init(value: "2026/1/1"), expiredAt: .distantFuture),
            executorId: "test",
            executedAt: .distantPast
        )
    )
}
