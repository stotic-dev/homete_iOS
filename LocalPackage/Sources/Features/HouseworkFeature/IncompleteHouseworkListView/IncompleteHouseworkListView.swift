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

    public static func make() -> some View {
        IncompleteHouseworkListView()
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

}

#if DEBUG
#Preview("IncompleteHouseworkListView_未完了あり") {
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
}

#Preview("IncompleteHouseworkListView_未完了なし") {
    let today = Date.previewDate(year: 2026, month: 5, day: 18)
    NavigationStack {
        IncompleteHouseworkListView()
    }
    .environment(\.now, today)
    .environment(HouseworkListStore())
    .setupEnvironmentForPreview()
}
#endif
