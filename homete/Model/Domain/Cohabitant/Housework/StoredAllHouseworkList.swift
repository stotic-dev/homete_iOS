//
//  StoredAllHouseworkList.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/16.
//

import Foundation

struct StoredAllHouseworkList: Equatable, Sendable {
    
    private(set) var value: [DailyHouseworkList]
    
    static func makeMultiDateList(items: [HouseworkItem], calendar: Calendar) -> Self {
        
        let items: [DailyHouseworkList] = Dictionary(grouping: items) { $0.formattedIndexedDate }
            .compactMap {
                
                guard let firstItem = $1.first else { return nil }
                return .init(
                    items: $1,
                    metaData: .init(indexedDate: firstItem.indexedDate, expiredAt: firstItem.expiredAt)
                )
            }
        return .init(value: items)
    }
    
    func item(_ item: HouseworkItem) -> HouseworkItem? {
        
        guard let targetDayList = value.first(
            where: { $0.metaData.indexedDate == item.indexedDate }
        ),
              let targetItem = targetDayList.items.first(where: { $0.id == item.id }) else { return nil }
        return targetItem
    }
    
    mutating func removeAll() {
        value = []
    }
}
