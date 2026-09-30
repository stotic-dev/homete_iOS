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
    @Environment(\.now) var now

    var houseworkListStore: HouseworkListStore
    let state: HouseworkState
    let list: HouseworkBoardList
    /// 完了した家事の担当者名を引くための同居人一覧
    let memberList: CohabitantMemberList
    @Binding var selectedHouseworkState: HouseworkState
    @Binding var isSelecting: Bool
    /// 選択中の家事のID
    ///
    /// 一括操作のボタンはナビゲーションバー側に置いているため、選択の保持は親のViewが行う
    @Binding var selectedIDs: Set<String>
    let onCreateTapped: () -> Void
    /// クイックアクションで「完了にする」が選ばれた。ハーフモーダルは親が出す
    let onSelectComplete: (HouseworkBoardItem) -> Void
    /// クイックアクションで「ありがとう」が選ばれた。ハーフモーダルは親が出す
    let onSelectThanks: (HouseworkBoardItem) -> Void

    @CommonError var commonError

    var body: some View {
        if let emptyReason = HouseworkBoardEmptyReason(list: list, state: state) {
            HouseworkBoardEmptyView(
                reason: emptyReason,
                onCreateTapped: onCreateTapped,
                onSwitchTab: { selectedHouseworkState = $0 }
            )
        } else {
            List(selection: isSelecting ? $selectedIDs : .constant([])) {
                ForEach(selection.items) { item in
                    let isSelectionDisabled = isSelecting && !selection.isSelectable(item)
                    houseworkItemRow(item)
                        .padding(.vertical, .space8)
                        .opacity(isSelectionDisabled ? 0.4 : 1)
                        .selectionDisabled(isSelectionDisabled)
                        .contextMenu {
                            HouseworkQuickActionMenuContent(
                                item: item,
                                step: .board,
                                onSelectComplete: { onSelectComplete(item) },
                                onSelectThanks: { onSelectThanks(item) },
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
                .commonError(content: $commonError)
        }
    }

}

private extension HouseworkBoardListContent {

    var selection: HouseworkSelection {
        .init(
            items: list.items(matching: state),
            state: state,
            selectedIDs: selectedIDs,
            ownUserId: loginContext.account.id
        )
    }

    func houseworkItemRow(_ item: HouseworkBoardItem) -> some View {
        Button {
            navigationPath.push(.houseworkDetail(item))
        } label: {
            let completionInfo = completionInfo(of: item)
            HouseBoardListRow(
                houseworkItem: item.originalItem,
                completionInfo: completionInfo,
                onTapThanks: thanksAction(of: item, status: completionInfo?.thanksStatus)
            )
        }
    }

    /// ハートのタップで伝えられるのは、まだ伝えていない家事だけ。選択中はセルの選択を優先する
    func thanksAction(of item: HouseworkBoardItem, status: HouseworkThanksStatus?) -> (() -> Void)? {
        guard status == .notSent, !isSelecting else { return nil }

        return {
            Task {
                await sendThanks(to: item)
            }
        }
    }

    /// ハートのタップでは、メッセージを書かずにありがとうだけを伝える（コメントがないので通知は送らない）
    func sendThanks(to item: HouseworkBoardItem) async {
        guard let cohabitantId = loginContext.cohabitantId else { return }

        do {
            try await houseworkListStore.perform(
                .sendThanks,
                on: item,
                now: now,
                account: loginContext.account,
                cohabitantId: cohabitantId,
                step: .board
            )
        } catch {
            commonError = .init(error: error)
        }
    }

    /// 完了リストの家事セルに出す、担当者とありがとうの状況
    ///
    /// 未完了リストには担当者もありがとうもないため出さない。
    func completionInfo(of item: HouseworkBoardItem) -> HouseBoardListRow.CompletionInfo? {
        guard state == .completed else { return nil }

        return .init(
            executorNames: item.executors.compactMap { memberList.userName($0.userId) },
            thanksStatus: HouseworkThanksStatus.make(item: item, ownUserId: loginContext.account.id)
        )
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
        memberList: .init(value: [], ownId: ""),
        selectedHouseworkState: $selectedState,
        isSelecting: $isSelecting,
        selectedIDs: .constant([]),
        onCreateTapped: {},
        onSelectComplete: { _ in },
        onSelectThanks: { _ in }
    )
    .setupLoginContextForPreview()
}

#Preview("HouseworkBoardListContent_選択モード") {
    @Previewable @State var selectedState = HouseworkState.completed
    @Previewable @State var isSelecting = true
    HouseworkBoardListContent(
        houseworkListStore: .init(
            houseworkClient: .previewValue,
            cohabitantPushNotificationClient: .previewValue
        ),
        state: .completed,
        list: .init(items: [
            .makeForPreview(
                id: "1",
                title: "洗濯",
                point: 20,
                indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
                state: .completed,
                executorId: "otherUserId"
            ),
            .makeForPreview(
                id: "2",
                title: "掃除",
                point: 100,
                indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
                state: .completed,
                executorId: "otherUserId"
            ),
            .makeForPreview(
                id: "3",
                title: "料理",
                point: 1,
                indexedDate: .init(value: .previewDate(year: 2026, month: 1, day: 1)),
                state: .completed,
                executorId: "ownUserId"
            ),
        ]),
        memberList: .init(
            value: [
                .init(id: "ownUserId", userName: "たろう"),
                .init(id: "otherUserId", userName: "はなこ"),
            ],
            ownId: "ownUserId"
        ),
        selectedHouseworkState: $selectedState,
        isSelecting: $isSelecting,
        selectedIDs: .constant(["1"]),
        onCreateTapped: {},
        onSelectComplete: { _ in },
        onSelectThanks: { _ in }
    )
    .setupLoginContextForPreview()
}
#endif
