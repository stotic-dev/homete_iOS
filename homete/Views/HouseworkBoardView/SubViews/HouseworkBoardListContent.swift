//
//  HouseworkBoardListContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import SwiftUI

struct HouseworkBoardListContent: View {
    
    @Environment(\.appNavigationPath) var navigationPath
    
    let houseworkList: [HouseworkItem]
    let onApproveRequest: (HouseworkItem) async -> Void
    let onDelete: (HouseworkItem) async -> Void
    
    var body: some View {
        List {
            ForEach(houseworkList) { item in
                houseworkItemRow(item)
                    .padding(.vertical, DesignSystem.Space.space8)
            }
            .listRowSpacing(.zero)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
}

private extension HouseworkBoardListContent {
    
    func houseworkItemRow(_ item: HouseworkItem) -> some View {
        Button {
            // TODO: 家事詳細画面に遷移する
            navigationPath.push(.houseworkDetail)
        } label: {
            HouseBoardListRow(
                houseworkItem: item,
                onDelete: onDelete
            )
        }
        .swipeActions(edge: .trailing) {
            Button {
                Task {
                    await onApproveRequest(item)
                }
            } label: {
                Label("完了", systemImage: "checkmark.seal.fill")
            }
            .tint(.primary1)
        }
    }
}

#Preview {
    HouseworkBoardListContent(
        houseworkList: [
            .init(id: "1", indexedDate: .now, title: "洗濯", point: 20, state: .incomplete, expiredAt: .now),
            .init(id: "2", indexedDate: .now, title: "掃除", point: 100, state: .incomplete, expiredAt: .now),
            .init(id: "3", indexedDate: .now, title: "料理", point: 1, state: .incomplete, expiredAt: .now)
        ],
        onApproveRequest: { _ in },
        onDelete: { _ in }
    )
}
