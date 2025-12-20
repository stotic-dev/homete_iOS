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
    
    func updateState(_ nextState: HouseworkState, at now: Date, changer: String) -> Self {
        
        return .init(
            id: id,
            indexedDate: indexedDate,
            title: title,
            point: point,
            state: nextState,
            executorId: nextState == .pendingApproval ? changer : executorId,
            executedAt: nextState == .pendingApproval ? now : executedAt,
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
        executedAt: Date? = nil
    ) {
        
        self.init(
            id: id,
            indexedDate: metaData.indexedDate,
            title: title,
            point: point,
            state: state,
            executorId: nil,
            executedAt: executedAt,
            expiredAt: metaData.expiredAt
        )
    }
}
