//
//  DailyHouseworkMetaData.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/08.
//

import Foundation

struct DailyHouseworkMetaData: Equatable {
    
    let indexedDate: Date
    let expiredAt: Date
}

extension DailyHouseworkMetaData {
    
    init(selectedDate: Date, calendar: Calendar) {
        
        let indexedDate = calendar.startOfDay(for: selectedDate)
        let expiredAt = calendar.date(byAdding: .month, value: 1, to: indexedDate) ?? indexedDate
        self.init(indexedDate: indexedDate, expiredAt: expiredAt)
    }
}
