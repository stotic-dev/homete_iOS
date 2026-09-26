//
//  MonthlyRecurrenceRule.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/09/26.
//

import Foundation

/// 毎月の繰り返しルール
public enum MonthlyRecurrenceRule: Sendable, Hashable {

    /// 毎月◯日（1〜31）。その日がない月は月末に表示する
    case dayOfMonth(Int)

    /// 指定日がこのルールに当てはまるかを返す
    public func matches(_ date: Date, calendar: Calendar) -> Bool {
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count else { return false }
        let day = calendar.component(.day, from: date)

        switch self {
        case let .dayOfMonth(targetDay):
            return day == min(targetDay, daysInMonth)
        }
    }

}

// MARK: - Codable

/// Firestore上では `{ type, day }` の形で保存する。種類を増やせるように`type`を持たせている（ADR-0022）
extension MonthlyRecurrenceRule: Codable {

    private enum CodingKeys: String, CodingKey {

        case type
        case day

    }

    private enum RuleType: String, Codable {

        case dayOfMonth

    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(RuleType.self, forKey: .type) {
        case .dayOfMonth:
            self = try .dayOfMonth(container.decode(Int.self, forKey: .day))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .dayOfMonth(day):
            try container.encode(RuleType.dayOfMonth, forKey: .type)
            try container.encode(day, forKey: .day)
        }
    }

}
