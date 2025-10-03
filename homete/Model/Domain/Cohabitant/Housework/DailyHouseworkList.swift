//
//  DailyHouseworkList.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/08.
//

import Foundation

struct DailyHouseworkList: Equatable, Sendable {
    
    let items: [HouseworkItem]
    let metaData: DailyHouseworkMetaData
    
    static func makeInitialValue(selectedDate: Date, items: [HouseworkItem], calendar: Calendar) -> Self {
        
        return .init(
            items: items,
            metaData: .init(selectedDate: selectedDate, calendar: calendar)
        )
    }
    
    static func makeMultiDateList(items: [HouseworkItem], calendar: Calendar) -> [Self] {
        
        Dictionary(grouping: items) { $0.formattedIndexedDate }
            .compactMap {
                
                guard let firstItem = $1.first else { return nil }
                return .init(
                    items: $1,
                    metaData: .init(indexedDate: firstItem.indexedDate, expiredAt: firstItem.expiredAt)
                )
            }
    }
    
    /// この日付の家事情報がすでに登録済みであること
    var isRegistered: Bool { !items.isEmpty }
    
    /// すでに同じ家事が登録されているかどうか
    func isAlreadyRegistered(_ item: HouseworkItem) -> Bool {
        
        return items.contains { $0.title == item.title }
    }
}
