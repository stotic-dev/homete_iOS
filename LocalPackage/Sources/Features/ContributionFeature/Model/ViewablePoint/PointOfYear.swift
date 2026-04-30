//
//  PointOfYear.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

struct PointOfYear: Equatable, Hashable, ViewablePointList {

    let userId: String
    let userName: String
    let displayPeriod: DisplayPointPeriod.PeriodType
    let total: Point
    let elements: Set<PointOfMonth>
    let dateRange: ClosedRange<Date>

    func hash(into hasher: inout Hasher) {

        hasher.combine(displayPeriod)
    }

    static func make(
        by dayOfPoints: [PointOfDay],
        userId: String,
        userName: String,
        dateRange: ClosedRange<Date>,
        calendar: Calendar
    ) -> Self {

        let targetPoints = dayOfPoints.filter { dateRange.contains($0.indexedDay) }
        let months = PointOfMonth.makeWithSeparated(by: targetPoints, userId: userId, userName: userName, calendar: calendar)
        let total = months.reduce(Point(value: .zero)) { partialResult, pointOfMonth in
            return .init(value: partialResult.value + pointOfMonth.total.value)
        }

        return .init(
            userId: userId,
            userName: userName,
            displayPeriod: .year,
            total: total,
            elements: .init(months),
            dateRange: dateRange
        )
    }
}
