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
            pointLabel(houseworkItem.point)
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

private extension HouseBoardListRow {
    
    func pointLabel(_ point: Int) -> some View {
        Text(point.formatted())
            .font(with: .headLineM)
            .foregroundStyle(.commonWhite)
            .padding(DesignSystem.Space.space8)
            .frame(minWidth: 45)
            .background {
                GeometryReader {
                    RoundedRectangle(cornerRadius: $0.size.height / 2)
                        .fill(.primary2)
                }
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
