//
//  HouseworkIndexedDate.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/06.
//

import Foundation

struct HouseworkIndexedDate: Equatable, Codable, Hashable {
    
    let value: String
    
    static func calcTargetPeriod(
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

extension HouseworkIndexedDate {
    
    init(_ date: Date, calendar: Calendar) {
        let formatStyle = Date.FormatStyle(
            date: .numeric,
            time: .omitted,
            calendar: calendar,
            timeZone: calendar.timeZone
        )
            .year(.extended(minimumLength: 4))
            .month(.twoDigits)
            .day(.twoDigits)
        value = date.formatted(formatStyle)
    }
}
