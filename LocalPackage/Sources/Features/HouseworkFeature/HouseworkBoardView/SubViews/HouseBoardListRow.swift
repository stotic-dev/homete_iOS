//
//  HouseBoardListRow.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/10/28.
//

import HometeDomain
import HometeUI
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
                indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
                expiredAt: .distantPast
            )
        )
    )
}
