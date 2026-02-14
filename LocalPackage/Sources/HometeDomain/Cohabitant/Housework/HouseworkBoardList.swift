//
//  HouseworkBoardList.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import Foundation

public struct HouseworkBoardList: Equatable {

    public private(set) var items: [HouseworkItem]

    public func items(matching state: HouseworkState) -> [HouseworkItem] {
        print("HouseworkBoardList filtering(state: \(state), items: \(items))")
        return items.filter { $0.state == state }
    }

    public init(items: [HouseworkItem]) {
        self.items = items
    }
}

public extension HouseworkBoardList {

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
