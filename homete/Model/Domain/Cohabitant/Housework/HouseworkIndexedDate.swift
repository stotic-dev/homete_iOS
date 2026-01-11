//
//  HouseworkIndexedDate.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/06.
//

import Foundation

struct HouseworkIndexedDate: Equatable, Codable, Hashable {
    let value: String
    
    var mapValue: [String: String] {
        
        return ["value": value]
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
