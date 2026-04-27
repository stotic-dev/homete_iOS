//
//  DailyHouseworkMetaData.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/08.
//

import Foundation

public struct DailyHouseworkMetaData: Equatable, Sendable {

    public let indexedDate: HouseworkIndexedDate
    public let expiredAt: Date

    public init(indexedDate: HouseworkIndexedDate, expiredAt: Date) {
        self.indexedDate = indexedDate
        self.expiredAt = expiredAt
    }
}

public extension DailyHouseworkMetaData {

    init(selectedDate: Date, calendar: Calendar) {

        let selectedDay = calendar.startOfDay(for: selectedDate)
        let indexedDate = HouseworkIndexedDate(value: selectedDay)
        let expiredAt = calendar.date(byAdding: .year, value: 1, to: selectedDay) ?? selectedDay
        self.init(indexedDate: indexedDate, expiredAt: expiredAt)
    }
}
