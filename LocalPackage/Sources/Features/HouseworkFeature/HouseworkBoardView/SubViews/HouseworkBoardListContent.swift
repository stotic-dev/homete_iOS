//
//  HouseworkBoardListContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import HometeDomain
import HometeUI
import SwiftUI

/// 家事ボードの1ページ（未完了・完了のどちらか）の一覧
///
/// 渡された家事を並べてタップを伝えるだけのUIで、家事の操作や遷移は呼び出し側が行う。
struct HouseworkBoardListContent<RowMenu: View>: View {

    let state: HouseworkState
    let list: HouseworkBoardList
    /// 完了した家事の担当者名を引くための同居人一覧
    let memberList: CohabitantMemberList
    /// ログイン中のユーザーのID。ありがとうの状況と、選択できる家事の判定に使う
    let ownUserId: String
    /// 一覧がタブバーの裏まで伸びている分の高さ
    ///
    /// 終端までスクロールしたときに最後の行がタブバーに隠れないよう、この分を余白として足す
    let bottomContentInset: CGFloat
    @Binding var selectedHouseworkState: HouseworkState
    @Binding var isSelecting: Bool
    /// 選択中の家事のID
    ///
    /// 一括操作のボタンはナビゲーションバー側に置いているため、選択の保持は親のViewが行う
    @Binding var selectedIDs: Set<String>
    let onCreateTapped: () -> Void
    let onTapItem: (HouseworkBoardItem) -> Void
    /// ハートのタップで、メッセージを書かずにありがとうだけを伝える
    let onTapThanks: (HouseworkBoardItem) -> Void
    /// 家事のセルを長押ししたときのメニューの中身
    @ViewBuilder let rowMenu: (HouseworkBoardItem) -> RowMenu

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
                            rowMenu(item)
                        }
                }
                .listRowBackground(Color.clear)
                #if os(iOS)
                    .listRowSpacing(.zero)
                    .listRowSeparator(.hidden)
                #endif
            }
            .listStyle(.plain)
            // 終端までスクロールしたときに、最後の行が浮いている追加ボタンやタブバーに隠れないようにする。
            // 高さをリテラルで持つとボタンのデザイン変更に追従できないため、同じボタンを隠して置いて実寸を使う
            .safeAreaInset(edge: .bottom) {
                AddHouseworkButton {}
                    .padding(.bottom, .space24)
                    .padding(.bottom, bottomContentInset)
                    .hidden()
            }
            #if os(iOS)
            .environment(\.editMode, .constant(isSelecting ? .active : .inactive))
            #endif
        }
    }

}

private extension HouseworkBoardListContent {

    var selection: HouseworkSelection {
        .init(
            items: list.items(matching: state),
            state: state,
            selectedIDs: selectedIDs,
            ownUserId: ownUserId
        )
    }

    func houseworkItemRow(_ item: HouseworkBoardItem) -> some View {
        Button {
            onTapItem(item)
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

        return { onTapThanks(item) }
    }

    /// 完了リストの家事セルに出す、担当者とありがとうの状況
    ///
    /// 未完了リストには担当者もありがとうもないため出さない。
    func completionInfo(of item: HouseworkBoardItem) -> HouseBoardListRow.CompletionInfo? {
        guard state == .completed else { return nil }

        return .init(
            executorNames: item.executors.compactMap { memberList.userName($0.userId) },
            thanksStatus: HouseworkThanksStatus.make(item: item, ownUserId: ownUserId)
        )
    }

}

#if DEBUG
#Preview {
    @Previewable @State var selectedState = HouseworkState.incomplete
    @Previewable @State var isSelecting = false
    HouseworkBoardListContent(
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
        ownUserId: "ownUserId",
        bottomContentInset: .zero,
        selectedHouseworkState: $selectedState,
        isSelecting: $isSelecting,
        selectedIDs: .constant([]),
        onCreateTapped: {},
        onTapItem: { _ in },
        onTapThanks: { _ in },
        rowMenu: { _ in EmptyView() }
    )
}

#Preview("HouseworkBoardListContent_選択モード") {
    @Previewable @State var selectedState = HouseworkState.completed
    @Previewable @State var isSelecting = true
    HouseworkBoardListContent(
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
        ownUserId: "ownUserId",
        bottomContentInset: .zero,
        selectedHouseworkState: $selectedState,
        isSelecting: $isSelecting,
        selectedIDs: .constant(["1"]),
        onCreateTapped: {},
        onTapItem: { _ in },
        onTapThanks: { _ in },
        rowMenu: { _ in EmptyView() }
    )
}
#endif
