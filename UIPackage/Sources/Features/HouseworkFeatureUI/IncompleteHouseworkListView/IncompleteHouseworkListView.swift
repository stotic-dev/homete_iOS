//
//  IncompleteHouseworkListView.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/05/18.
//

import HometeModel
import HometeUI
import SwiftUI

/// 今日の未完了の家事の一覧
/// - Note: 完了・クイックアクションの処理は`IncompleteHouseworkListScreen`が受け持ち、行のメニューを差し込む
public struct IncompleteHouseworkListView<RowMenu: View>: View {

    let summary: TodayHouseworkSummary
    /// 行をタップしたときの処理。家事詳細への遷移は、ナビゲーションを持つ呼び出し元に任せる
    let onSelectItem: (HouseworkBoardItem) -> Void
    let onTapComplete: (HouseworkBoardItem) -> Void
    /// 長押しのメニューと、その他ボタンのメニューで同じ中身を出す
    @ViewBuilder let rowMenu: (HouseworkBoardItem) -> RowMenu

    public init(
        summary: TodayHouseworkSummary,
        onSelectItem: @escaping (HouseworkBoardItem) -> Void,
        onTapComplete: @escaping (HouseworkBoardItem) -> Void,
        @ViewBuilder rowMenu: @escaping (HouseworkBoardItem) -> RowMenu
    ) {
        self.summary = summary
        self.onSelectItem = onSelectItem
        self.onTapComplete = onTapComplete
        self.rowMenu = rowMenu
    }

    public var body: some View {
        contentView(summary: summary)
            // ホームからの遷移で地の色が変わらないよう、ホームと同じミルク色にする
            .background(.backgroundScreen)
            .navigationTitle(.localized("未完了の家事"))
            .inlineNavigationBarTitleDisplayMode()
            .softTopScrollEdgeEffect()
    }

}

private extension IncompleteHouseworkListView {

    @ViewBuilder
    func contentView(summary: TodayHouseworkSummary) -> some View {
        if summary.incompleteItems.isEmpty {
            Text("未完了の家事はありません", bundle: #bundle)
                .font(with: .body)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(summary.incompleteItems) { item in
                    houseworkItemRow(item)
                        .padding(.vertical, .space8)
                        .contextMenu {
                            rowMenu(item)
                        }
                        .listRowBackground(Color.clear)
                    #if os(iOS)
                        .listRowSpacing(.zero)
                        .listRowSeparator(.hidden)
                    #endif
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    func houseworkItemRow(_ item: HouseworkBoardItem) -> some View {
        HouseBoardListRow(
            houseworkItem: item.originalItem,
            // 未完了の家事には担当者もありがとうも無いので、完了リスト向けの表示は渡さない
            completionInfo: nil,
            showsCompleteButton: item.state == .incomplete,
            // 未完了の家事だけを並べる画面なので、出せるアクションは状態だけで決まる
            showsMoreButton: !HouseworkQuickAction.actions(for: item.state).isEmpty,
            onTapRow: { onSelectItem(item) },
            onTapThanks: nil,
            onTapComplete: { onTapComplete(item) },
            menuContent: { rowMenu(item) }
        )
    }

}

#if DEBUG
#Preview("IncompleteHouseworkListView_未完了あり") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    var calendar = Calendar.japanese
    calendar.timeZone = .tokyo
    let summary = TodayHouseworkSummary.make(
        storedAllItems: .init(value: [
            .init(
                items: [
                    .makeForPreview(title: "洗濯", point: 20),
                    .makeForPreview(title: "掃除", point: 30),
                    .makeForPreview(
                        title: "料理",
                        point: 50,
                        state: .completed
                    ),
                ],
                metaData: .init(
                    indexedDate: .init(value: today)
                )
            ),
        ]),
        template: nil,
        now: today,
        calendar: calendar
    )
    return NavigationStack {
        IncompleteHouseworkListView(summary: summary, onSelectItem: { _ in }, onTapComplete: { _ in }) { _ in
            EmptyView()
        }
    }
    .environment(\.now, today)
    .setupEnvironmentForPreview()
}

#Preview("IncompleteHouseworkListView_未完了なし") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    NavigationStack {
        IncompleteHouseworkListView(
            summary: TodayHouseworkSummary.make(
                storedAllItems: .init(value: []),
                template: nil,
                now: today,
                calendar: .japanese
            ),
            onSelectItem: { _ in },
            onTapComplete: { _ in }
        ) { _ in
            EmptyView()
        }
    }
    .environment(\.now, today)
    .setupEnvironmentForPreview()
}
#endif
