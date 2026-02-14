//
//  HouseworkIndexedDate.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/06.
//

import Foundation

public struct HouseworkIndexedDate: Equatable, Codable, Hashable, Sendable {

    public let value: String

    public init(value: String) {
        self.value = value
    }

    public static func calcTargetPeriod(
        anchorDate: Date,
        offsetDays: Int,
        calendar: Calendar
    ) -> [[String: String]] {

        let base = calendar.startOfDay(for: anchorDate)
        guard offsetDays >= 0 else {

            return [["value": HouseworkIndexedDate(base, calendar: calendar).value]]
        }
        // -offset ... +offset の範囲を列挙
        return (-offsetDays...offsetDays).compactMap { delta in

            guard let date = calendar.date(byAdding: .day, value: delta, to: base) else { return nil }
            return ["value": HouseworkIndexedDate(date, calendar: calendar).value]
        }
    }
}

public extension HouseworkIndexedDate {

    init(_ date: Date, calendar: Calendar) {
        let formatStyle = Date.FormatStyle(
            date: .numeric,
            time: .omitted,
            locale: calendar.locale ?? .autoupdatingCurrent,
            calendar: calendar,
            timeZone: calendar.timeZone
        )
            .year(.extended(minimumLength: 4))
            .month(.twoDigits)
            .day(.twoDigits)
        value = date.formatted(formatStyle)
    }
}
