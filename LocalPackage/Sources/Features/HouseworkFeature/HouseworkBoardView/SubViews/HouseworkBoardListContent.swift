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
    @Binding var isSelecting: Bool
    let onCreateTapped: () -> Void

    @State var selectedIDs: Set<String> = []
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
            List(selection: isSelecting ? $selectedIDs : .constant([])) {
                ForEach(list.items(matching: state)) { item in
                    houseworkItemRow(item)
                        .padding(.vertical, .space8)
                        .contextMenu {
                            HouseworkQuickActionMenuContent(
                                item: item,
                                onError: { commonError = .init(error: $0) }
                            )
                        }
                }
                .listRowBackground(Color.clear)
                #if os(iOS)
                    .listRowSpacing(.zero)
                    .listRowSeparator(.hidden)
                #endif
            }
            .listStyle(.plain)
            #if os(iOS)
                .environment(\.editMode, .constant(isSelecting ? .active : .inactive))
            #endif
                .safeAreaInset(edge: .bottom) {
                    if isSelecting {
                        HouseworkBulkActionBar(
                            state: state,
                            selectedItems: list.items(matching: state).filter { selectedIDs.contains($0.id) },
                            onError: { commonError = .init(error: $0) },
                            onCompleted: { selectedIDs = [] }
                        )
                    }
                }
                .onChange(of: isSelecting) {
                    selectedIDs = []
                }
                .commonError(content: $commonError)
        }
    }

}

private extension HouseworkBoardListContent {

    func houseworkItemRow(_ item: HouseworkBoardItem) -> some View {
        Button {
            navigationPath.push(.houseworkDetail(item))
        } label: {
            HouseBoardListRow(houseworkItem: item.originalItem)
        }
    }

}

#if DEBUG
#Preview {
    @Previewable @State var selectedState = HouseworkState.incomplete
    @Previewable @State var isSelecting = false
    HouseworkBoardListContent(
        houseworkListStore: .init(
            houseworkClient: .previewValue,
            cohabitantPushNotificationClient: .previewValue
        ),
        state: .incomplete,
        list: .init(items: [
            .makeForPreview(
                id: "1",
                title: "洗濯",
                point: 20,
                indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1))
            ),
            .makeForPreview(
                id: "2",
                title: "掃除",
                point: 100,
                indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1))
            ),
            .makeForPreview(
                id: "3",
                title: "料理",
                point: 1,
                indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1))
            ),
        ]),
        selectedHouseworkState: $selectedState,
        isSelecting: $isSelecting,
        onCreateTapped: {}
    )
}
#endif
