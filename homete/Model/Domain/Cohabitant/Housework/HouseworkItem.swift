//
//  HouseworkItem.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import Foundation

struct HouseworkItem: Identifiable, Equatable, Sendable, Hashable {
    
    let id: String
    let indexedDate: Date
    let title: String
    let point: Int
    let state: HouseworkState
    let executorId: String?
    let executedAt: Date?
    let expiredAt: Date
    
    var formattedIndexedDate: String {
        
        return indexedDate.formatted(Date.FormatStyle.houseworkDateFormatStyle)
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

extension HouseworkItem: Codable {
    
    init(from decoder: any Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        let indexedDateString = try container.decode(String.self, forKey: .indexedDate)
        
        guard let date = try? Date.FormatStyle.houseworkDateFormatStyle.parse(indexedDateString) else {
            
            throw DecodingError.dataCorruptedError(
                forKey: .indexedDate,
                in: container,
                debugDescription: "Invalid date format"
            )
        }
        indexedDate = date
        title = try container.decode(String.self, forKey: .title)
        point = try container.decode(Int.self, forKey: .point)
        state = try container.decode(HouseworkState.self, forKey: .state)
        executorId = try container.decode(String.self, forKey: .executorId)
        executedAt = try container.decode(Date.self, forKey: .executedAt)
        expiredAt = try container.decode(Date.self, forKey: .expiredAt)
    }
    
    func encode(to encoder: any Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(formattedIndexedDate, forKey: .indexedDate)
        try container.encode(title, forKey: .title)
        try container.encode(point, forKey: .point)
        try container.encode(state, forKey: .state)
        try container.encode(executorId, forKey: .executorId)
        try container.encode(executedAt, forKey: .executedAt)
        try container.encode(expiredAt, forKey: .expiredAt)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, indexedDate, title, point, state, executorId, executedAt, expiredAt
    }
}
