//
//  DateHelper.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/04.
//

import Foundation

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
