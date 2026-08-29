//
//  TodayHouseworkSummaryHelper.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/05/18.
//

import HometeDomain

extension TodayHouseworkSummary {

    static func makeForTest(
        allItems: [HouseworkItem] = [],
        incompleteItems: [HouseworkBoardItem] = [],
        progress: Double = 0,
        displayState: DisplayState = .empty,
        displayIncompleteItems: [HouseworkBoardItem] = [],
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
