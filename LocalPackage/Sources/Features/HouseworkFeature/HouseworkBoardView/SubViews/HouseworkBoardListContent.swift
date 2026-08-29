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
                    let isSelectionDisabled = isSelecting && !isCoSelectable(item)
                    houseworkItemRow(item)
                        .padding(.vertical, .space8)
                        .opacity(isSelectionDisabled ? 0.4 : 1)
                        .selectionDisabled(isSelectionDisabled)
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
                            selectedItems: selectedItems,
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

    var selectedItems: [HouseworkBoardItem] {
        list.items(matching: state).filter { selectedIDs.contains($0.id) }
    }

    /// 選択中の家事と一緒に選択できるか
    ///
    /// 一括操作は選択した全ての家事に同じアクションを適用するため、対応可能アクションが異なる
    /// 家事（承認待ちでも自分が承認依頼を出したもの等）は混ぜて選択できないようにする。
    func isCoSelectable(_ item: HouseworkBoardItem) -> Bool {
        HouseworkQuickAction.isCoSelectable(
            item,
            with: selectedItems,
            ownUserId: loginContext.account.id
        )
    }

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
