//
//  HouseworkBoardList.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import Foundation

struct HouseworkBoardList: Equatable {
    
    private(set) var items: [HouseworkItem]
    
    func items(matching state: HouseworkState) -> [HouseworkItem] {
        
        return items.filter { $0.state == state }
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
                calendar.startOfDay(for: $0.metaData.indexedDate) == calendar.startOfDay(for: selectedDate)
            }?.items ?? []
    }
}
