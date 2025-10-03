//
//  HouseworkDateFormatStyle.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/29.
//

import Foundation

struct HouseworkDateFormatStyle: FormatStyle {
    typealias FormatInput = Date
    typealias FormatOutput = String
    
    private let formatter: DateFormatter

    func format(_ value: Date) -> String {
        return formatter.string(from: value)
    }
}

extension HouseworkDateFormatStyle: ParseStrategy {
    
    func parse(_ value: String) throws -> Date {
        if let date = formatter.date(from: value) {
            return date
        }
        throw ParseError()
    }
    
    struct ParseError: Error {}
}

extension HouseworkDateFormatStyle {
    
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

extension Date.FormatStyle {
    
    static let houseworkDateFormatStyle = HouseworkDateFormatStyle()
}
