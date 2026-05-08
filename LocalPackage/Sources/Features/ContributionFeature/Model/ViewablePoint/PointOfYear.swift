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

    func hash(into hasher: inout Hasher) {

        hasher.combine(userId)
    }

    static func make(
        by pointOfDayByDate: [Date: PointOfDay],
        userId: String,
        userName: String,
        dates: [Date],
        calendar: Calendar
    ) -> Self {

        let targetDataByDate = pointOfDayByDate.filter { _, pointOfDay in
            dates.contains {
                calendar.isDate($0, equalTo: pointOfDay.indexedDay, toGranularity: .month)
            }
        }
        let months = PointOfMonth.makeWithSeparated(
            by: targetDataByDate,
            userId: userId,
            userName: userName,
            calendar: calendar
        )
        let allMonths: [PointOfMonth] = dates.map { targetMonth in
            guard let month = months.first(where: {
                calendar.isDate($0.startDate, equalTo: targetMonth, toGranularity: .month)
            }) else {
                let startOfMonth = calendar.date(
                    from: calendar.dateComponents([.year, .month], from: targetMonth)
                ) ?? targetMonth
                return .init(
                    userId: userId,
                    userName: userName,
                    total: .init(value: .zero),
                    elements: [],
                    startDate: startOfMonth
                )
            }
            return month
        }

        let total = months.reduce(Point(value: .zero)) { partialResult, pointOfMonth in
            return .init(value: partialResult.value + pointOfMonth.total.value)
        }

        return .init(
            userId: userId,
            userName: userName,
            total: total,
            elements: .init(allMonths)
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
