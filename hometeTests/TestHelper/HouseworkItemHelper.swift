//
//  HouseworkItemHelper.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/10/02.
//

import Foundation
@testable import homete

extension HouseworkItem {
    
    static func makeForTest(
        id: Int,
        indexedDate: Date = .now,
        title: String = "title",
        point: Int = 100,
        state: HouseworkState = .incomplete,
        expiredAt: Date = .now
    ) -> Self {
        
        return .init(
            id: "id\(id.formatted())",
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: state,
            expiredAt: expiredAt
        )
    }
}
