//
//  HouseworkBoardListContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import HometeDomain
import HometeUI
import SwiftUI

struct HouseworkBoardListContent: View {

    @Environment(\.houseworkBoardNavigationPath) var navigationPath
    @Environment(\.loginContext) var loginContext

    var houseworkListStore: HouseworkListStore
    let state: HouseworkState
    let list: HouseworkBoardList
    @Binding var selectedHouseworkState: HouseworkState
    let onCreateTapped: () -> Void

    @CommonError var commonError

    var body: some View {
        if let emptyReason = HouseworkBoardEmptyReason(
            list: list,
            state: state,
            ownUserId: loginContext.account.id
        ) {
            HouseworkBoardEmptyView(
                reason: emptyReason,
                onCreateTapped: onCreateTapped,
                onSwitchTab: { selectedHouseworkState = $0 }
            )
        } else {
            List {
                ForEach(list.items(matching: state)) { item in
                    houseworkItemRow(item)
                        .padding(.vertical, .space8)
                }
                .listRowBackground(Color.clear)
                #if os(iOS)
                .listRowSpacing(.zero)
                .listRowSeparator(.hidden)
                #endif
            }
            .listStyle(.plain)
            .commonError(content: $commonError)
        }
    }
}

private extension HouseworkBoardListContent {
    
    func houseworkItemRow(_ item: HouseworkItem) -> some View {
        Button {
            navigationPath.push(.houseworkDetail(item))
        } label: {
            HouseBoardListRow(houseworkItem: item)
        }
        #if os(iOS)
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
        #endif
    }
}

// プレゼンテーションロジック

private extension HouseworkBoardListContent {
    
    func didSwipeDeleteItemAction(_ item: HouseworkItem) async {
        
        guard let cohabitantId = loginContext.cohabitantId else { return }
        do {
            
            try await houseworkListStore.remove(
                target: item,
                cohabitantId: cohabitantId
            )
        }
        catch {
            
            commonError = .init(error: error)
        }
    }
}

#Preview {
    @Previewable @State var selectedState = HouseworkState.incomplete
    HouseworkBoardListContent(
        houseworkListStore: .init(
            houseworkClient: .previewValue,
            cohabitantPushNotificationClient: .previewValue
        ),
        state: .incomplete,
        list: .init(items: [
            .init(
                id: "1",
                title: "洗濯",
                point: 20,
                metaData: .init(indexedDate: .init(value: "2026/1/1"), expiredAt: .now)
            ),
            .init(
                id: "2",
                title: "掃除",
                point: 100,
                metaData: .init(indexedDate: .init(value: "2026/1/1"), expiredAt: .now)
            ),
            .init(
                id: "3",
                title: "料理",
                point: 1,
                metaData: .init(indexedDate: .init(value: "2026/1/1"), expiredAt: .now)
            )
        ]),
        selectedHouseworkState: $selectedState,
        onCreateTapped: {}
    )
}
