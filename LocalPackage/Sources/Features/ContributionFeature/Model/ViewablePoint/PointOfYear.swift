//
//  PointOfYear.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

struct PointOfYear: Equatable, Hashable {

    let userId: String
    let userName: String
    let total: Point
    let elements: Set<PointOfMonth>
    let dateRange: ClosedRange<Date>

    func hash(into hasher: inout Hasher) {

        hasher.combine(dateRange.lowerBound)
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
            total: total,
            elements: .init(months),
            dateRange: dateRange
        )
    }
}

extension PointOfYear: GenerableViewablePointList {
    
    func generate() -> ViewablePointList {
        
        return .init(
            userId: userId,
            userName: userName,
            total: total,
            elements: .init(elements.map { .init(point: $0.total, date: $0.startDate) })
        )
    }
}
