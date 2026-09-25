//
//  HouseworkRecurrenceInput.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/09/26.
//

import Foundation

/// 繰り返し方の入力状態
///
/// 種類を切り替えても他の種類の入力値を失わないよう、全種類の値を持っておき、`recurrence`で選択中の種類の値だけを取り出す。
public struct HouseworkRecurrenceInput: Sendable, Equatable {

    public enum Kind: Sendable, CaseIterable {

        /// くり返さない
        case none
        /// 毎週
        case weekly
        /// 毎月◯日
        case monthlyDay
        /// 毎月第N◯曜日
        case monthlyWeekday

    }

    public var kind: Kind
    public var weekdays: Set<DayOfWeek>
    public var dayOfMonth: Int
    public var ordinal: WeekOrdinal
    public var monthlyDayOfWeek: DayOfWeek

    /// 選択中の種類の繰り返し方。くり返さない場合や、毎週で曜日が1つも選ばれていない場合は`nil`
    public var recurrence: HouseworkRecurrence? {
        switch kind {
        case .none:
            nil

        case .weekly:
            weekdays.isEmpty ? nil : .weekly(weekdays)

        case .monthlyDay:
            .monthly(.dayOfMonth(dayOfMonth))

        case .monthlyWeekday:
            .monthly(.weekdayOfMonth(ordinal: ordinal, dayOfWeek: monthlyDayOfWeek))
        }
    }

    /// 入力が完了しているか（くり返さない、または繰り返し方が決まっている）
    public var isValid: Bool {
        kind == .none || recurrence != nil
    }

    public init(
        kind: Kind,
        weekdays: Set<DayOfWeek> = [],
        dayOfMonth: Int = 1,
        ordinal: WeekOrdinal = .first,
        monthlyDayOfWeek: DayOfWeek = .monday
    ) {
        self.kind = kind
        self.weekdays = weekdays
        self.dayOfMonth = dayOfMonth
        self.ordinal = ordinal
        self.monthlyDayOfWeek = monthlyDayOfWeek
    }

}

public extension HouseworkRecurrenceInput {

    /// 既存の繰り返し方から入力状態を作る
    init(recurrence: HouseworkRecurrence) {
        switch recurrence {
        case let .weekly(weekdays):
            self.init(kind: .weekly, weekdays: weekdays)

        case let .monthly(.dayOfMonth(day)):
            self.init(kind: .monthlyDay, dayOfMonth: day)

        case let .monthly(.weekdayOfMonth(ordinal, dayOfWeek)):
            self.init(kind: .monthlyWeekday, ordinal: ordinal, monthlyDayOfWeek: dayOfWeek)
        }
    }

    /// 指定日を基準に、各種類の初期値（その日の曜日・日付・第N週）を埋めた入力状態を作る
    /// - Note: 29日以降は第5週になりうるため、第Nの初期値は「最終」にする
    init(kind: Kind, basedOn date: Date, calendar: Calendar) {
        let dayOfWeek = DayOfWeek.of(date: date, calendar: calendar) ?? .monday
        let day = calendar.component(.day, from: date)
        self.init(
            kind: kind,
            weekdays: [dayOfWeek],
            dayOfMonth: day,
            ordinal: WeekOrdinal(rawValue: (day - 1) / 7 + 1) ?? .last,
            monthlyDayOfWeek: dayOfWeek
        )
    }

}
