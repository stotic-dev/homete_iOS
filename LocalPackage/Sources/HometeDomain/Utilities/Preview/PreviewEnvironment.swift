//
//  PreviewEnvironment.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/20.
//

import SwiftUI

public extension Calendar {
    static var japanese: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .tokyo
        calendar.locale = .ja
        return calendar
    }
}

public extension TimeZone {
    // swiftlint:disable:next force_unwrapping
    static let tokyo = TimeZone(identifier: "Asia/Tokyo")!
}

public extension Locale {
    static let ja = Locale(identifier: "ja_JP")
}

public extension View {
    func setupEnvironmentForPreview() -> some View {
        self
            .environment(\.locale, .ja)
            .environment(\.timeZone, .tokyo)
            .environment(\.calendar, .japanese)
    }
}

public extension Date {
    static func previewDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = .zero,
        minute: Int = .zero,
        second: Int = .zero
    ) -> Date {
        DateComponents(
            calendar: .japanese,
            timeZone: .tokyo,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        .date! // swiftlint:disable:this force_unwrapping
    }
}
