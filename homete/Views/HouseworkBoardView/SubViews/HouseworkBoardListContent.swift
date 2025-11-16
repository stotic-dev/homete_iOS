//
//  HouseworkBoardListContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import SwiftUI

struct HouseworkBoardListContent: View {
    
    @Environment(\.appNavigationPath) var navigationPath
    
    var houseworkListStore: HouseworkListStore
    let state: HouseworkState
    let list: HouseworkBoardList
    
    @CommonError var commonError
    
    var body: some View {
        List {
            ForEach(list.items(matching: state)) { item in
                houseworkItemRow(item)
                    .padding(.vertical, DesignSystem.Space.space8)
            }
            .listRowSpacing(.zero)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .commonError(content: $commonError)
    }
}

private extension HouseworkBoardListContent {
    
    func houseworkItemRow(_ item: HouseworkItem) -> some View {
        Button {
            navigationPath.push(.houseworkDetail(item: item))
        } label: {
            HouseBoardListRow(houseworkItem: item)
        }
        .swipeActions(edge: .trailing) {
            Button {
                Task {
                    await didSwipeDeleteItemAction(item)
                }
            } label: {
                Text("削除")
            }
            .tint(.red)
        }
    }
}

// プレゼンテーションロジック

private extension HouseworkBoardListContent {
    
    func didSwipeDeleteItemAction(_ item: HouseworkItem) async {
        
        do {
            
            try await houseworkListStore.remove(item)
        }
        catch {
            
            commonError = .init(error: error)
        }
    }
}

#Preview {
    HouseworkBoardListContent(
        houseworkListStore: .init(
            houseworkClient: .previewValue,
            cohabitantPushNotificationClient: .previewValue
        ),
        state: .incomplete,
        list: .init(items: [
            .init(id: "1", title: "洗濯", point: 20, metaData: .init(indexedDate: .now, expiredAt: .now)),
            .init(id: "2", title: "掃除", point: 100, metaData: .init(indexedDate: .now, expiredAt: .now)),
            .init(id: "3", title: "料理", point: 1, metaData: .init(indexedDate: .now, expiredAt: .now))
        ])
    )
}
