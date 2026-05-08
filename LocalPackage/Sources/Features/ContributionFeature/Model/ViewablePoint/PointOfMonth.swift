//
//  PointOfMonth.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

struct PointOfMonth: Equatable, Hashable {

    let userId: String
    let userName: String
    let total: Point
    let elements: Set<PointOfDay>
    let startDate: Date

    func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
        hasher.combine(startDate)
    }

    static func make(
        by pointOfDayByDate: [Date: PointOfDay],
        userId: String,
        userName: String,
        dates: [Date],
        calendar: Calendar
    ) -> Self {

        let allDays: [PointOfDay] = dates.map { targetDate in
            pointOfDayByDate[calendar.startOfDay(for: targetDate)]
                ?? .init(indexedDay: targetDate, point: .init(value: .zero), achievedCount: .zero)
        }

        return .init(
            userId: userId,
            userName: userName,
            total: calcTotalPoint(allDays),
            elements: .init(allDays),
            startDate: dates.first ?? Date()
        )
    }

    /// 月毎に分けた月間ポイントのリスト
    static func makeWithSeparated(
        by pointOfDayByDate: [Date: PointOfDay],
        userId: String,
        userName: String,
        calendar: Calendar
    ) -> [Self] {

        let separetedDic = pointOfDayByDate.values
            .reduce([DateComponents: Set<PointOfDay>]()) { partialResult, pointOfDay in

            let month = monthComponent(pointOfDay: pointOfDay, calendar: calendar)
            var result = partialResult

            if let elements = result[month] {
                var currentMonthElements = elements
                currentMonthElements.insert(pointOfDay)
                result[month] = currentMonthElements
            } else {
                result[month] = [pointOfDay]
            }

            return result
        }

        return separetedDic.compactMap { components, elements in
            guard let startDate = calendar.date(from: components) else { return nil }
            return .init(
                userId: userId,
                userName: userName,
                    total: calcTotalPoint(.init(elements)),
                elements: elements,
                startDate: startDate
            )
        }
    }
}

extension PointOfMonth: GenerableViewablePointList {

    func generate() -> ViewablePointList {

        return .init(
            userId: userId,
            userName: userName,
            total: total,
            elements: .init(elements.map { .init(point: $0.point, date: $0.indexedDay) })
        )
    }
}

private extension PointOfMonth {

    static func monthComponent(pointOfDay: PointOfDay, calendar: Calendar) -> DateComponents {

        return calendar.dateComponents([.year, .month], from: pointOfDay.indexedDay)
    }

    static func calcTotalPoint(_ pointOfDay: [PointOfDay]) -> Point {

        return pointOfDay.reduce(Point(value: .zero), { partialResult, pointOfDay in
            return .init(value: partialResult.value + pointOfDay.point.value)
        })
    }
}
