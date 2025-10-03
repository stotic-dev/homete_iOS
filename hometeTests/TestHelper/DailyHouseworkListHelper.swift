//
//  DailyHouseworkListHelper.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/10/02.
//

@testable import homete

extension DailyHouseworkList {
    
    static func makeForTest(items: [HouseworkItem]) -> Self {
        
        let indexedDate = items[0].indexedDate
        let expiredAt = items[0].expiredAt
        return .init(items: items, metaData: .init(indexedDate: indexedDate, expiredAt: expiredAt))
    }
}
