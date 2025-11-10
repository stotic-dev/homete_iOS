//
//  HouseBoardListRow.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/10/28.
//

import SwiftUI

struct HouseBoardListRow: View {
    
    let houseworkItem: HouseworkItem
    let onDelete: (HouseworkItem) async -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Space.space16) {
            PointLabel(point: houseworkItem.point)
            Text(houseworkItem.title)
                .font(with: .body)
            Spacer()
        }
        .tag(houseworkItem.id)
        .swipeActions(edge: .trailing) {
            Button {
                Task {
                    await onDelete(houseworkItem)
                }
            } label: {
                Text("削除")
            }
            .tint(.red)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    HouseBoardListRow(
        houseworkItem: .init(
            id: "1",
            indexedDate: .now,
            title: "洗濯",
            point: 20,
            state: .incomplete,
            expiredAt: .now
        )
    ) { _ in }
}
