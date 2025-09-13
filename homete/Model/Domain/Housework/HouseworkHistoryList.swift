//
//  HouseworkHistoryList.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import Foundation

struct HouseworkHistoryList: Equatable {
    
    var items: [String]
}

extension HouseworkHistoryList: Codable {
    
    enum CodingKeys: String, CodingKey {
        case items
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode(Array<String>.self, forKey: .items)
    }
}

extension HouseworkHistoryList: RawRepresentable {
    
    init?(rawValue: String) {
        
        guard let data = rawValue.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(HouseworkHistoryList.self, from: data) else {
            
            return nil
        }
        self = decoded
    }
    
    var rawValue: String {
        
        guard
            let data = try? JSONEncoder().encode(self),
            let jsonString = String(data: data, encoding: .utf8) else {
            
            return ""
        }
        return jsonString
    }
}
