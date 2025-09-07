//
//  DailyHouseworkList.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/08.
//

import Foundation

struct DailyHouseworkList: Equatable {
    
    let indexedDate: Date
    let metaData: DailyHouseworkMetaData
    let items: [HouseworkItem]
    
    static func makeInitialValue(selectedDate: Date, items: [HouseworkItem], calendar: Calendar) -> Self {
        
        let indexedDate = calendar.startOfDay(for: selectedDate)
        let metaData = DailyHouseworkMetaData(
            expiredAt: calendar.date(byAdding: .month, value: 3, to: indexedDate) ?? indexedDate
        )
        return .init(
            indexedDate: indexedDate,
            metaData: metaData,
            items: items
        )
    }
    
    /// この日付の家事情報がすでに登録済みであること
    var isRegistered: Bool { !items.isEmpty }
    
    /// すでに同じ家事が登録されているかどうか
    func isAlreadyRegistered(_ item: HouseworkItem) -> Bool {
        
        return items.contains { $0.title == item.title }
    }
}
