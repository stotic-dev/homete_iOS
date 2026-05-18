//
//  TodayHouseworkSummaryHelper.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/05/18.
//

import HometeDomain
@testable import HouseworkFeature

extension TodayHouseworkSummary {

    static func makeForTest(
        allItems: [HouseworkItem] = [],
        incompleteItems: [HouseworkItem] = [],
        progress: Double = 0,
        displayState: DisplayState = .empty,
        displayIncompleteItems: [HouseworkItem] = [],
        hasMoreIncomplete: Bool = false
    ) -> Self {
        .init(
            allItems: allItems,
            incompleteItems: incompleteItems,
            progress: progress,
            displayState: displayState,
            displayIncompleteItems: displayIncompleteItems,
            hasMoreIncomplete: hasMoreIncomplete
        )
    }

}
