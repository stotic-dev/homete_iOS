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
    @Environment(HouseworkListStore.self) var houseworkListStore

    public static func make() -> some View {
        IncompleteHouseworkListView()
    }

    public var body: some View {
        let summary = TodayHouseworkSummary(allItems: todayItems)
        contentView(summary: summary)
            .navigationTitle("未完了の家事")
            .inlineNavigationBarTitleDisplayMode()
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
                    HouseBoardListRow(houseworkItem: item)
                        .padding(.vertical, .space8)
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

    var todayItems: [HouseworkItem] {
        let today = calendar.startOfDay(for: now)
        return houseworkListStore.items.value
            .first { $0.metaData.indexedDate.value == today }?
            .items ?? []
    }

}

#if DEBUG
    #Preview("未完了あり") {
        let today = Date.previewDate(year: 2026, month: 5, day: 18)
        NavigationStack {
            IncompleteHouseworkListView()
        }
        .environment(\.now, today)
        .environment(
            HouseworkListStore(
                items: [
                    .init(
                        items: [
                            .init(
                                id: "1",
                                title: "洗濯",
                                point: 20,
                                metaData: .init(
                                    indexedDate: .init(value: today),
                                    expiredAt: .distantFuture
                                )
                            ),
                            .init(
                                id: "2",
                                title: "掃除",
                                point: 30,
                                metaData: .init(
                                    indexedDate: .init(value: today),
                                    expiredAt: .distantFuture
                                ),
                                state: .pendingApproval
                            ),
                            .init(
                                id: "3",
                                title: "料理",
                                point: 50,
                                metaData: .init(
                                    indexedDate: .init(value: today),
                                    expiredAt: .distantFuture
                                ),
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
    }

    #Preview("未完了なし") {
        let today = Date.previewDate(year: 2026, month: 5, day: 18)
        NavigationStack {
            IncompleteHouseworkListView()
        }
        .environment(\.now, today)
        .environment(HouseworkListStore())
        .setupEnvironmentForPreview()
    }
#endif
