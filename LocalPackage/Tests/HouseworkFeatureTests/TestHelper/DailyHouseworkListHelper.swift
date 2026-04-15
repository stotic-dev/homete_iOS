//
//  DailyHouseworkListHelper.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/10/02.
//

import HometeDomain
@testable import HouseworkFeature

extension DailyHouseworkList {
    
    static func makeForTest(items: [HouseworkItem]) -> Self {
        
        let indexedDate = items[0].indexedDate
        let expiredAt = items[0].expiredAt
        return .init(items: items, metaData: .init(indexedDate: indexedDate, expiredAt: expiredAt))
    }
}
