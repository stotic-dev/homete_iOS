//
//  HouseworkBoardView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import HometeDomain
import HometeUI
import SwiftUI

/// 家事ボードのUI
///
/// 渡された値を描画してタップを伝えるだけで、Storeの操作・シートの表示・画面遷移は
/// `HouseworkBoardScreen`が行う。チュートリアルでも同じViewにサンプルの家事を渡して表示するため、
/// ここに`Environment`の依存やプレゼンテーションロジックを持ち込まない。
/// `NavigationStack`の中に置く前提で、ナビゲーションバーのボタンもここで並べる。
struct HouseworkBoardView<RowMenu: View>: View {

    @Binding var dateList: HouseworkDateList
    @Binding var selectedHouseworkState: HouseworkState
    @Binding var isSelecting: Bool
    /// 複数選択モードで選択中の家事のID
    @Binding var selectedHouseworkIDs: Set<String>

    let houseworkBoardList: HouseworkBoardList
    let members: CohabitantMemberList
    let ownUserId: String
    /// 家事の購読に失敗している場合のエラー内容
    let loadFailure: DomainError?
    let onTapRetry: () -> Void
    let onTapAdd: () -> Void
    let onTapItem: (HouseworkBoardItem) -> Void
    let onTapThanks: (HouseworkBoardItem) -> Void
    let onTapStorageLimit: () -> Void
    let onTapHouseworkTemplate: () -> Void
    let onTapBulkAction: (HouseworkQuickAction) -> Void
    /// 家事のセルを長押ししたときのメニューの中身
    @ViewBuilder let rowMenu: (HouseworkBoardItem) -> RowMenu

    var body: some View {
        // 一覧をタブバーの裏まで伸ばすと、一覧側からは下端のセーフエリアが見えなくなる。
        // 伸ばす前のここで測っておき、一覧の終端の余白として足し直す
        GeometryReader { proxy in
            boardBody(bottomSafeAreaInset: proxy.safeAreaInsets.bottom)
        }
        .softTopScrollEdgeEffect()
        .leadingToolbarItem {
            if isSelecting {
                cancelSelectingButton()
            }
        }
        .trailingToolbarItem {
            if isSelecting {
                bulkActionContent()
            } else {
                defaultToolbarContent()
            }
        }
        .onChange(of: selectedHouseworkState) {
            withAnimation {
                isSelecting = false
            }
        }
        // 選択モードの出入りで選択を持ち越さない（タブの切り替えも選択モードの終了を経由する）
        .onChange(of: isSelecting) {
            selectedHouseworkIDs = []
        }
    }

}

// MARK: - UI定義

private extension HouseworkBoardView {

    /// 表示中のタブと選択状態から組み立てた、複数選択の判定
    var selection: HouseworkSelection {
        .init(
            items: houseworkBoardList.items(matching: selectedHouseworkState),
            state: selectedHouseworkState,
            selectedIDs: selectedHouseworkIDs,
            ownUserId: ownUserId
        )
    }

    func boardBody(bottomSafeAreaInset: CGFloat) -> some View {
        ZStack {
            if let loadFailure {
                LoadErrorView(error: loadFailure, onTapRetry: onTapRetry)
            } else {
                boardContent(bottomSafeAreaInset: bottomSafeAreaInset)
            }
        }
        // 一覧の下に追加ボタンの分の余白を作り、終端までスクロールしても最後の家事行と重ならないようにする。
        // `overlay`で浮かせると一覧の上に乗るだけで余白ができず、行の右側（ポイント）が隠れてしまう
        .safeAreaInset(edge: .bottom, alignment: .trailing) {
            if loadFailure == nil {
                AddHouseworkButton(action: onTapAdd)
                    .padding(.trailing, .space24)
                    .padding(.bottom, .space24)
            }
        }
    }

    func boardContent(bottomSafeAreaInset: CGFloat) -> some View {
        VStack(spacing: .space16) {
            HouseworkDateHeaderContent(dateList: $dateList, onTapStorageLimit: onTapStorageLimit)
            VStack(spacing: .space16) {
                HouseworkBoardSegmentedControl(selectedHouseworkState: $selectedHouseworkState)
                TabView(selection: $selectedHouseworkState) {
                    ForEach(HouseworkState.pageableCases) { state in
                        HouseworkBoardListContent(
                            state: state,
                            list: houseworkBoardList,
                            memberList: members,
                            ownUserId: ownUserId,
                            bottomContentInset: bottomSafeAreaInset,
                            selectedHouseworkState: $selectedHouseworkState,
                            isSelecting: $isSelecting,
                            selectedIDs: $selectedHouseworkIDs,
                            onCreateTapped: onTapAdd,
                            onTapItem: onTapItem,
                            onTapThanks: onTapThanks,
                            rowMenu: rowMenu
                        )
                        .tag(state)
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
                // 一覧をタブバーの裏まで伸ばし、スクロールした中身がタブバー越しに透けて見えるようにする
                .ignoresSafeArea(edges: .bottom)
            }
            .padding(.horizontal, .space16)
        }
    }

    /// 選択モードでないときのナビゲーションバー右側（選択モードへの入口とテンプレート）
    func defaultToolbarContent() -> some View {
        HStack(spacing: .space16) {
            Button("選択") {
                withAnimation {
                    isSelecting = true
                }
            }
            NavigationBarButton(label: .houseworkTemplate, action: onTapHouseworkTemplate)
        }
    }

    /// 選択モードを抜けるボタン。左上に置いて、選択モードに入っていること自体を分かりやすくする
    func cancelSelectingButton() -> some View {
        NavigationBarButton(label: .close) {
            withAnimation {
                isSelecting = false
            }
        }
        .accessibilityLabel("選択をやめる")
    }

    func bulkActionContent() -> some View {
        HouseworkBulkActionToolbarContent(
            actions: selection.availableActions,
            isEnabled: !selection.isEmpty,
            onTap: onTapBulkAction
        )
    }

}

#if DEBUG
#Preview {
    let list = HouseworkBoardList(items: [
        .makeForPreview(
            title: "洗濯",
            point: 20
        ),
    ])
    NavigationStack {
        HouseworkBoardView(
            dateList: .constant(.init(
                anchorDate: .distantPast,
                selectedDate: .distantPast,
                calendar: .japanese
            )),
            selectedHouseworkState: .constant(.incomplete),
            isSelecting: .constant(false),
            selectedHouseworkIDs: .constant([]),
            houseworkBoardList: list,
            members: .init(value: [], ownId: "ownUserId"),
            ownUserId: "ownUserId",
            loadFailure: nil,
            onTapRetry: {},
            onTapAdd: {},
            onTapItem: { _ in },
            onTapThanks: { _ in },
            onTapStorageLimit: {},
            onTapHouseworkTemplate: {},
            onTapBulkAction: { _ in },
            rowMenu: { _ in EmptyView() }
        )
    }
    .apply(theme: .init())
    .setupEnvironmentForPreview()
    .environment(\.now, .distantPast)
}

#Preview("HouseworkBoardView_選択モード") {
    let list = HouseworkBoardList(items: [
        .makeForPreview(
            id: "1",
            title: "洗濯",
            point: 20
        ),
        .makeForPreview(
            id: "2",
            title: "掃除",
            point: 100
        ),
    ])
    NavigationStack {
        HouseworkBoardView(
            dateList: .constant(.init(
                anchorDate: .distantPast,
                selectedDate: .distantPast,
                calendar: .japanese
            )),
            selectedHouseworkState: .constant(.incomplete),
            isSelecting: .constant(true),
            selectedHouseworkIDs: .constant(["1"]),
            houseworkBoardList: list,
            members: .init(value: [], ownId: "ownUserId"),
            ownUserId: "ownUserId",
            loadFailure: nil,
            onTapRetry: {},
            onTapAdd: {},
            onTapItem: { _ in },
            onTapThanks: { _ in },
            onTapStorageLimit: {},
            onTapHouseworkTemplate: {},
            onTapBulkAction: { _ in },
            rowMenu: { _ in EmptyView() }
        )
    }
    .apply(theme: .init())
    .setupEnvironmentForPreview()
    .environment(\.now, .distantPast)
}

#Preview("HouseworkBoardView_完了") {
    let list = HouseworkBoardList(items: [
        .makeForPreview(
            id: "1",
            title: "洗濯",
            point: 20,
            state: .completed,
            executorId: "otherUserId"
        ),
        .makeForPreview(
            id: "2",
            title: "掃除",
            point: 100,
            state: .completed,
            executorId: "ownUserId"
        ),
    ])
    NavigationStack {
        HouseworkBoardView(
            dateList: .constant(.init(
                anchorDate: .distantPast,
                selectedDate: .distantPast,
                calendar: .japanese
            )),
            selectedHouseworkState: .constant(.completed),
            isSelecting: .constant(false),
            selectedHouseworkIDs: .constant([]),
            houseworkBoardList: list,
            members: .init(
                value: [
                    .init(id: "ownUserId", userName: "たろう"),
                    .init(id: "otherUserId", userName: "はなこ"),
                ],
                ownId: "ownUserId"
            ),
            ownUserId: "ownUserId",
            loadFailure: nil,
            onTapRetry: {},
            onTapAdd: {},
            onTapItem: { _ in },
            onTapThanks: { _ in },
            onTapStorageLimit: {},
            onTapHouseworkTemplate: {},
            onTapBulkAction: { _ in },
            rowMenu: { _ in EmptyView() }
        )
    }
    .apply(theme: .init())
    .setupEnvironmentForPreview()
    .environment(\.now, .distantPast)
}

#Preview("HouseworkBoardView_読み込みエラー") {
    NavigationStack {
        HouseworkBoardView(
            dateList: .constant(.init(
                anchorDate: .distantPast,
                selectedDate: .distantPast,
                calendar: .japanese
            )),
            selectedHouseworkState: .constant(.incomplete),
            isSelecting: .constant(false),
            selectedHouseworkIDs: .constant([]),
            houseworkBoardList: .init(items: []),
            members: .init(value: [], ownId: "ownUserId"),
            ownUserId: "ownUserId",
            loadFailure: .noNetwork,
            onTapRetry: {},
            onTapAdd: {},
            onTapItem: { _ in },
            onTapThanks: { _ in },
            onTapStorageLimit: {},
            onTapHouseworkTemplate: {},
            onTapBulkAction: { _ in },
            rowMenu: { _ in EmptyView() }
        )
    }
    .apply(theme: .init())
    .setupEnvironmentForPreview()
    .environment(\.now, .distantPast)
}

#Preview("HouseworkBoardView_家事が多い") {
    let list = HouseworkBoardList(items: (1 ... 10).map { index in
        HouseworkBoardItem.makeForPreview(
            id: "\(index)",
            title: "家事\(index)",
            point: index * 10
        )
    })
    NavigationStack {
        HouseworkBoardView(
            dateList: .constant(.init(
                anchorDate: .distantPast,
                selectedDate: .distantPast,
                calendar: .japanese
            )),
            selectedHouseworkState: .constant(.incomplete),
            isSelecting: .constant(false),
            selectedHouseworkIDs: .constant([]),
            houseworkBoardList: list,
            members: .init(value: [], ownId: "ownUserId"),
            ownUserId: "ownUserId",
            loadFailure: nil,
            onTapRetry: {},
            onTapAdd: {},
            onTapItem: { _ in },
            onTapThanks: { _ in },
            onTapStorageLimit: {},
            onTapHouseworkTemplate: {},
            onTapBulkAction: { _ in },
            rowMenu: { _ in EmptyView() }
        )
    }
    .apply(theme: .init())
    .setupEnvironmentForPreview()
    .environment(\.now, .distantPast)
}
#endif
