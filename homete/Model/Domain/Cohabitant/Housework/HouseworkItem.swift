//
//  HouseworkItem.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import Foundation

struct HouseworkItem: Identifiable, Equatable {
    
    let id: String
    let indexedDate: Date
    let title: String
    let point: Int
    let state: HouseworkState
    let expiredAt: Date
    
    var formattedIndexedDate: String {
        
        return indexedDate.formatted(Date.FormatStyle.houseworkDateFormatStyle)
    }
}

extension HouseworkItem {
    
    init(id: String, title: String, point: Int, metaData: DailyHouseworkMetaData) {
        self.init(
            id: id,
            indexedDate: metaData.indexedDate,
            title: title,
            point: point,
            state: .incomplete,
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
        expiredAt = try container.decode(Date.self, forKey: .expiredAt)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(formattedIndexedDate, forKey: .indexedDate)
        try container.encode(title, forKey: .title)
        try container.encode(point, forKey: .point)
        try container.encode(state, forKey: .state)
        try container.encode(expiredAt, forKey: .expiredAt)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, indexedDate, title, point, state, expiredAt
    }
}
