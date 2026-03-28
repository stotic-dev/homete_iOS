//
//  HouseworkHistoryList.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import Foundation

public struct HouseworkHistoryList: Equatable {

    public private(set) var items: [String]

    public init(items: [String]) {
        self.items = items
    }

    /// 履歴があるかどうか
    public var hasHistory: Bool { !items.isEmpty }

    /// 引数に受け取った文字列が `items` に存在する場合、その要素を先頭へ移動します。
    /// - Parameter value: 先頭へ移動したい要素の文字列
    public mutating func moveToFrontIfExists(_ value: String) {

        guard let index = items.firstIndex(of: value) else { return }
        // 既に先頭なら何もしない
        if index == items.startIndex { return }
        let element = items.remove(at: index)
        items.insert(element, at: 0)
    }

    /// 引数に受け取った文字列を `items`の先頭に追加する
    /// - Parameter value: 新しい履歴文字
    public mutating func addNewHistory(_ value: String) {

        guard items.contains(value) else {

            items.insert(value, at: 0)
            return
        }
        moveToFrontIfExists(value)
    }
}

extension HouseworkHistoryList: Codable {

    enum CodingKeys: String, CodingKey {
        case items
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode(Array<String>.self, forKey: .items)
    }
}

extension HouseworkHistoryList: RawRepresentable {

    public init?(rawValue: String) {

        guard let data = rawValue.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(HouseworkHistoryList.self, from: data) else {

            return nil
        }
        self = decoded
    }

    public var rawValue: String {

        guard
            let data = try? JSONEncoder().encode(self),
            let jsonString = String(data: data, encoding: .utf8) else {

            return ""
        }
        return jsonString
    }
}
