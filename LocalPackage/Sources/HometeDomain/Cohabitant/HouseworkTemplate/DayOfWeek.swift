//
//  DayOfWeek.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import Foundation

/// 曜日を表す型。`Calendar.component(.weekday, from:)`（1=日曜, 7=土曜）との相互変換ロジックを持つ。
public enum DayOfWeek: Int, Codable, Sendable, CaseIterable, Identifiable, Hashable {

    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6

    public var id: Int {
        rawValue
    }

    /// 月曜始まりの表示順
    public static let displayOrdered: [DayOfWeek] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday,
    ]

    public var fullLabel: String {
        switch self {
        case .sunday: "日曜日"
        case .monday: "月曜日"
        case .tuesday: "火曜日"
        case .wednesday: "水曜日"
        case .thursday: "木曜日"
        case .friday: "金曜日"
        case .saturday: "土曜日"
        }
    }

    /// `Calendar.component(.weekday, from:)` の戻り値（1=日曜, 7=土曜）から生成する
    public init?(calendarWeekday: Int) {
        self.init(rawValue: calendarWeekday - 1)
    }

    /// 指定日付の曜日を返す
    public static func of(date: Date, calendar: Calendar) -> DayOfWeek? {
        DayOfWeek(calendarWeekday: calendar.component(.weekday, from: date))
    }

}
