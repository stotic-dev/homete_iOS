//
//  DateHelper.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/22.
//

import Foundation

extension Date {
    static func dateComponents(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = .zero,
        minute: Int = .zero,
        second: Int = .zero,
        calendar: Calendar = .current
    ) -> Date {
        DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        .date!
    }
}
