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
        executorId: String? = nil,
        executedAt: Date? = nil,
        expiredAt: Date = .now
    ) -> Self {
        
        return .init(
            id: "id\(id.formatted())",
            indexedDate: .init(indexedDate),
            title: title,
            point: point,
            state: state,
            executorId: executorId,
            executedAt: executedAt,
            expiredAt: expiredAt
        )
    }
    
    func updateProperties(
        indexedDate: HouseworkIndexedDate? = nil,
        title: String? = nil,
        point: Int? = nil,
        state: HouseworkState? = nil,
        executorId: String? = nil,
        executedAt: Date? = nil,
        expiredAt: Date? = nil
    ) -> HouseworkItem {
        
        let inputIndexedDate = indexedDate ?? self.indexedDate
        let inputTitle = title ?? self.title
        let inputPoint = point ?? self.point
        let inputState = state ?? self.state
        let inputExecutorId = executorId ?? self.executorId
        let inputExecutedAt = executedAt ?? self.executedAt
        let inputExpiredAt = expiredAt ?? self.expiredAt
        
        return .init(
            id: id,
            indexedDate: inputIndexedDate,
            title: inputTitle,
            point: inputPoint,
            state: inputState,
            executorId: inputExecutorId,
            executedAt: inputExecutedAt,
            expiredAt: inputExpiredAt
        )
    }
}
