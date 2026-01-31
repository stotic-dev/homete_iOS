//
//  DailyHouseworkMetaData.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/08.
//

import Foundation

struct DailyHouseworkMetaData: Equatable {
    
    let indexedDate: HouseworkIndexedDate
    let expiredAt: Date
}

extension DailyHouseworkMetaData {
    
    init(selectedDate: Date, calendar: Calendar) {
        
        let indexedDate = HouseworkIndexedDate(selectedDate, calendar: calendar)
        let expiredAt = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        self.init(indexedDate: indexedDate, expiredAt: expiredAt)
    }
}
