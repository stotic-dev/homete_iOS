//
//  HouseworkHistoryList.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import Foundation

struct HouseworkHistoryList: Equatable {
    
    private(set) var items: [String]
    
    /// 履歴があるかどうか
    var hasHistory: Bool { !items.isEmpty }
    
    /// 引数に受け取った文字列が `items` に存在する場合、その要素を先頭へ移動します。
    /// - Parameter value: 先頭へ移動したい要素の文字列
    mutating func moveToFrontIfExists(_ value: String) {
        
        guard let index = items.firstIndex(of: value) else { return }
        // 既に先頭なら何もしない
        if index == items.startIndex { return }
        let element = items.remove(at: index)
        items.insert(element, at: 0)
    }
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
