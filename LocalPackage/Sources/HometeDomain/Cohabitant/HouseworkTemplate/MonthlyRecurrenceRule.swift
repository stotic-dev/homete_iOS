//
//  MonthlyRecurrenceRule.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/09/26.
//

import Foundation

/// 月の中で何週目かを表す
public enum WeekOrdinal: Int, Codable, Sendable, CaseIterable, Hashable {

    case first = 1
    case second = 2
    case third = 3
    case fourth = 4
    /// 最終週（第5週はある月とない月があるため、代わりにこちらを使う）
    case last = -1

}

/// 毎月の繰り返しルール
public enum MonthlyRecurrenceRule: Sendable, Hashable {

    /// 毎月◯日（1〜31）。その日がない月は月末に表示する
    case dayOfMonth(Int)
    /// 毎月第N◯曜日
    case weekdayOfMonth(ordinal: WeekOrdinal, dayOfWeek: DayOfWeek)

    /// 指定日がこのルールに当てはまるかを返す
    public func matches(_ date: Date, calendar: Calendar) -> Bool {
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count else { return false }
        let day = calendar.component(.day, from: date)

        switch self {
        case let .dayOfMonth(targetDay):
            return day == min(targetDay, daysInMonth)

        case let .weekdayOfMonth(ordinal, dayOfWeek):
            guard DayOfWeek.of(date: date, calendar: calendar) == dayOfWeek else { return false }
            switch ordinal {
            case .last:
                return day + 7 > daysInMonth

            case .first, .second, .third, .fourth:
                return (day - 1) / 7 + 1 == ordinal.rawValue
            }
        }
    }

}

// MARK: - Codable

/// Firestore上では `{ type, day?, ordinal?, dayOfWeek? }` の形で保存する（ADR-0020）
extension MonthlyRecurrenceRule: Codable {

    private enum CodingKeys: String, CodingKey {

        case type
        case day
        case ordinal
        case dayOfWeek

    }

    private enum RuleType: String, Codable {

        case dayOfMonth
        case weekdayOfMonth

    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(RuleType.self, forKey: .type) {
        case .dayOfMonth:
            self = try .dayOfMonth(container.decode(Int.self, forKey: .day))

        case .weekdayOfMonth:
            self = try .weekdayOfMonth(
                ordinal: container.decode(WeekOrdinal.self, forKey: .ordinal),
                dayOfWeek: container.decode(DayOfWeek.self, forKey: .dayOfWeek)
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .dayOfMonth(day):
            try container.encode(RuleType.dayOfMonth, forKey: .type)
            try container.encode(day, forKey: .day)

        case let .weekdayOfMonth(ordinal, dayOfWeek):
            try container.encode(RuleType.weekdayOfMonth, forKey: .type)
            try container.encode(ordinal, forKey: .ordinal)
            try container.encode(dayOfWeek, forKey: .dayOfWeek)
        }
    }

}
