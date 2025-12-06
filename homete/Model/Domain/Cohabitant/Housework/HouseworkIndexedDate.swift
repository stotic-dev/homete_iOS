//
//  HouseworkIndexedDate.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/06.
//

import Foundation

struct HouseworkIndexedDate: Equatable, Codable, Hashable {
    let value: String
}

extension HouseworkIndexedDate {
    private static let formatStyle = Date.FormatStyle(date: .numeric, time: .omitted)
    init(_ date: Date, locale: Locale = .init(identifier: "ja_JP")) {
        value = date.formatted(
            Self.formatStyle
                .locale(locale)
        )
    }
}
