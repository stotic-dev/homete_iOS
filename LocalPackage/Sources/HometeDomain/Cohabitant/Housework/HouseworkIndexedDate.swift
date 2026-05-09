//
//  HouseworkIndexedDate.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/06.
//

import Foundation

public struct HouseworkIndexedDate: Equatable, Codable, Hashable, Sendable {

    public let value: Date

    public init(value: Date) {
        self.value = value
    }

    public static func calcTargetPeriod(
        anchorDate: Date,
        offsetDays: Int,
        calendar: Calendar
    ) -> [Date] {

        let base = calendar.startOfDay(for: anchorDate)
        guard offsetDays >= 0 else {

            return [base]
        }
        // -offset ... +offset の範囲を列挙
        return (-offsetDays...offsetDays).compactMap { delta in

            guard let date = calendar.date(byAdding: .day, value: delta, to: base) else { return nil }
            return date
        }
    }
}
