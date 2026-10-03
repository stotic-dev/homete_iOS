//
//  IncompleteHouseworkListView.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/05/18.
//

import HometeDomain
import HometeUI
import SwiftUI

public struct IncompleteHouseworkListView: View {

    @Environment(\.calendar) var calendar
    @Environment(\.now) var now
    @Environment(\.houseworkTemplateContext) var templateContext
    @Environment(\.houseworkStoragePolicy) var storagePolicy
    @Environment(HouseworkListStore.self) var houseworkListStore

    @CommonError var commonError
    /// クイックアクションの「完了にする」で、担当者を選ぶハーフモーダルを出している家事
    @State var completingItem: HouseworkBoardItem?

    /// 行をタップしたときの処理。家事詳細への遷移は、ナビゲーションを持つ呼び出し元に任せる
    let onSelectItem: (HouseworkBoardItem) -> Void

    public static func make(onSelectItem: @escaping (HouseworkBoardItem) -> Void) -> some View {
        IncompleteHouseworkListView(onSelectItem: onSelectItem)
    }

    public var body: some View {
        contentView(summary: TodayHouseworkSummary.make(
            storedAllItems: houseworkListStore.items,
            template: templateContext.templateOfDay(by: now, calendar: calendar),
            now: now,
            calendar: calendar,
            storagePolicy: storagePolicy
        )
        )
        .navigationTitle("未完了の家事")
        .inlineNavigationBarTitleDisplayMode()
        .softTopScrollEdgeEffect()
        .sheet(item: $completingItem) { item in
            HouseworkCompleteSheet(item: item, step: .dashboard)
        }
        .commonError(content: $commonError)
        .trackScreenView(.incompleteHouseworkList)
    }

}

private extension IncompleteHouseworkListView {

    @ViewBuilder
    func contentView(summary: TodayHouseworkSummary) -> some View {
        if summary.incompleteItems.isEmpty {
            Text("未完了の家事はありません")
                .font(with: .body)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(summary.incompleteItems) { item in
                    houseworkItemRow(item)
                        .padding(.vertical, .space8)
                        .contextMenu {
                            HouseworkQuickActionMenuContent(
                                item: item,
                                step: .dashboard,
                                // 未完了の家事だけを並べるため、ありがとうと手伝った人の追加は選ばれない
                                canAddHelper: false,
                                onSelectComplete: { completingItem = item },
                                onSelectThanks: {},
                                onSelectAddHelper: {},
                                onError: { commonError = .init(error: $0) }
                            )
                        }
                        .listRowBackground(Color.clear)
                    #if os(iOS)
                        .listRowSpacing(.zero)
                        .listRowSeparator(.hidden)
                    #endif
                }
            }
            .listStyle(.plain)
        }
    }

    func houseworkItemRow(_ item: HouseworkBoardItem) -> some View {
        Button {
            onSelectItem(item)
        } label: {
            HouseBoardListRow(houseworkItem: item.originalItem)
        }
    }

}

#if DEBUG
#Preview("IncompleteHouseworkListView_未完了あり") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    NavigationStack {
        IncompleteHouseworkListView.make { _ in }
    }
    .environment(\.now, today)
    .environment(
        HouseworkListStore(
            items: [
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
                        indexedDate: .init(value: today),
                        expiredAt: .distantFuture
                    )
                ),
            ]
        )
    )
    .setupEnvironmentForPreview()
    .setupLoginContextForPreview()
}

#Preview("IncompleteHouseworkListView_未完了なし") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    NavigationStack {
        IncompleteHouseworkListView.make { _ in }
    }
    .environment(\.now, today)
    .environment(HouseworkListStore())
    .setupEnvironmentForPreview()
    .setupLoginContextForPreview()
}
#endif
