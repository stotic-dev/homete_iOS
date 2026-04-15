//
//  HouseworkBoardList.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import Foundation
import HometeDomain

struct HouseworkBoardList: Equatable {

    private(set) var items: [HouseworkItem]

    func items(matching state: HouseworkState) -> [HouseworkItem] {
        return items.filter { $0.state == state }
    }

    init(items: [HouseworkItem]) {
        self.items = items
    }
}

extension HouseworkBoardList {

    init(
        dailyList: [DailyHouseworkList],
        selectedDate: Date,
        calendar: Calendar
    ) {

        items = dailyList
            .first {
                $0.metaData.indexedDate == .init(selectedDate, calendar: calendar)
            }?.items ?? []
    }
}
