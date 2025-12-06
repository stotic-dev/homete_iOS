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
        print("HouseworkBoardList filtering(state: \(state), items: \(items))")
        return items.filter { $0.state == state }
    }
}

extension HouseworkBoardList {
    
    init(
        dailyList: [DailyHouseworkList],
        selectedDate: Date,
        locale: Locale
    ) {
        
        items = dailyList
            .first {
                $0.metaData.indexedDate == .init(selectedDate, locale: locale)
            }?.items ?? []
    }
}
