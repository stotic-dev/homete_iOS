//
//  HouseworkItem.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import Foundation

struct HouseworkItem: Identifiable, Equatable, Sendable, Hashable, Codable {
    
    let id: String
    let indexedDate: HouseworkIndexedDate
    let title: String
    let point: Int
    let state: HouseworkState
    let executorId: String?
    let executedAt: Date?
    let expiredAt: Date
    
    var formattedIndexedDate: String {
        
        return indexedDate.value
    }
    
    func updatePendingApproval(at now: Date, changer: String) -> Self {
        
        return .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: .pendingApproval,
            executorId: changer,
            executedAt: now,
            expiredAt: expiredAt
        )
    }
    
    func updateIncomplete() -> Self {
        
        return .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: .incomplete,
            executorId: nil,
            executedAt: nil,
            expiredAt: expiredAt
        )
    }
    
    func isApprovable(_ userId: String) -> Bool {
        
        guard let executorId else { return false }
        return executorId != userId
    }
}

extension HouseworkItem {
    
    init(
        id: String,
        title: String,
        point: Int,
        metaData: DailyHouseworkMetaData,
        state: HouseworkState = .incomplete,
        executorId: String? = nil,
        executedAt: Date? = nil
    ) {
        
        self.init(
            id: id,
            indexedDate: metaData.indexedDate,
            title: title,
            point: point,
            state: state,
            executorId: executorId,
            executedAt: executedAt,
            expiredAt: metaData.expiredAt
        )
    }
}
