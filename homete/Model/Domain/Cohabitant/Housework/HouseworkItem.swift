//
//  HouseworkItem.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import Foundation

struct HouseworkItem: Identifiable, Equatable {
    
    let id: String
    let indexedDate: Date
    let title: String
    let point: Int
    let state: HouseworkState
    let expiredAt: Date
}

extension HouseworkItem {
    
    init(id: String, title: String, point: Int, metaData: DailyHouseworkMetaData) {
        self.init(
            id: id,
            indexedDate: metaData.indexedDate,
            title: title,
            point: point,
            state: .incomplete,
            expiredAt: metaData.expiredAt
        )
    }
}

extension HouseworkItem: Codable {
    
    init(from decoder: any Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        let indexedDateString = try container.decode(String.self, forKey: .indexedDate)
        
        guard let date = try? Date.FormatStyle.firestoreDateFormatStyle.parse(indexedDateString) else {
            
            throw DecodingError.dataCorruptedError(
                forKey: .indexedDate,
                in: container,
                debugDescription: "Invalid date format"
            )
        }
        indexedDate = date
        title = try container.decode(String.self, forKey: .title)
        point = try container.decode(Int.self, forKey: .point)
        state = try container.decode(HouseworkState.self, forKey: .state)
        expiredAt = try container.decode(Date.self, forKey: .expiredAt)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(indexedDate.formatted(Date.FormatStyle.firestoreDateFormatStyle), forKey: .indexedDate)
        try container.encode(title, forKey: .title)
        try container.encode(point, forKey: .point)
        try container.encode(state, forKey: .state)
        try container.encode(expiredAt, forKey: .expiredAt)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, indexedDate, title, point, state, expiredAt
    }
}

extension Date.FormatStyle {
    
    static let firestoreDateFormatStyle = YearMonthDayDashFormatStyle()
}

struct YearMonthDayDashFormatStyle: FormatStyle {
    typealias FormatInput = Date
    typealias FormatOutput = String
    
    private let formatter: DateFormatter

    func format(_ value: Date) -> String {
        return formatter.string(from: value)
    }
}

extension YearMonthDayDashFormatStyle: ParseStrategy {
    
    func parse(_ value: String) throws -> Date {
        if let date = formatter.date(from: value) {
            return date
        }
        throw ParseError()
    }
    
    struct ParseError: Error {}
}

extension YearMonthDayDashFormatStyle {
    
    init() {
        
        self.formatter = Self.getFormatter()
    }
    
    init(from decoder: any Decoder) throws {
        
        self.formatter = Self.getFormatter()
    }
    
    func encode(to encoder: any Encoder) throws {}
    
    private static func getFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}
