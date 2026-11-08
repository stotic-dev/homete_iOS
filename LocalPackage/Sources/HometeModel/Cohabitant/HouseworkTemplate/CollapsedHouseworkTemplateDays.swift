//
//  CollapsedHouseworkTemplateDays.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/21.
//

import Foundation

/// 家事テンプレート画面で折りたたまれている曜日の集合
public struct CollapsedHouseworkTemplateDays: Equatable {

    public private(set) var days: Set<DayOfWeek>

    public init(days: Set<DayOfWeek> = []) {
        self.days = days
    }

    /// 指定した曜日が折りたたまれているかどうか
    public func isCollapsed(_ day: DayOfWeek) -> Bool {
        days.contains(day)
    }

    /// 指定した曜日の折りたたみ状態を反転する
    public mutating func toggle(_ day: DayOfWeek) {
        if !days.insert(day).inserted {
            days.remove(day)
        }
    }

}

extension CollapsedHouseworkTemplateDays: Codable {

    enum CodingKeys: String, CodingKey {

        case days

    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(days, forKey: .days)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        days = try container.decode(Set<DayOfWeek>.self, forKey: .days)
    }

}

extension CollapsedHouseworkTemplateDays: RawRepresentable {

    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(CollapsedHouseworkTemplateDays.self, from: data) else {
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
