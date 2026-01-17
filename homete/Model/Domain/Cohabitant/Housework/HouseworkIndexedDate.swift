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
        calendar: Calendar,
        locale: Locale
    ) -> [[String: String]] {
        
        let base = calendar.startOfDay(for: anchorDate)
        guard offsetDays >= 0 else {
            
            return [["value": HouseworkIndexedDate(base, locale: locale).value]]
        }
        // -offset ... +offset の範囲を列挙
        return (-offsetDays...offsetDays).compactMap { delta in
            
            guard let date = calendar.date(byAdding: .day, value: delta, to: base) else { return nil }
            return ["value": HouseworkIndexedDate(date, locale: locale).value]
        }
    }
}

extension HouseworkIndexedDate {
    
    private static let formatStyle = Date.FormatStyle(date: .numeric, time: .omitted)
        .year(.extended(minimumLength: 4))
        .month(.twoDigits)
        .day(.twoDigits)
    
    init(_ date: Date, locale: Locale = .init(identifier: "ja_JP")) {
        value = date.formatted(
            Self.formatStyle
                .locale(locale)
        )
    }
}
