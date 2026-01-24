//
//  HouseBoardListRow.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/10/28.
//

import SwiftUI

struct HouseBoardListRow: View {
    
    let houseworkItem: HouseworkItem
    
    var body: some View {
        HStack(spacing: .space16) {
            PointLabel(point: houseworkItem.point)
            Text(houseworkItem.title)
                .font(with: .body)
            Spacer()
        }
        .tag(houseworkItem.id)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .init(
            id: "1",
            title: "洗濯",
            point: 20,
            metaData: .init(
                indexedDate: .init(value: "2026/1/1"),
                expiredAt: .distantPast
            )
        )
    )
}
