//
//  PointOfMonth.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

struct PointOfMonth: Equatable, Hashable, ViewablePointElement, ViewablePointList {

    let userId: String
    let userName: String
    let displayPeriod: DisplayPointPeriod.PeriodType
    let total: Point
    let elements: Set<PointOfDay>

    var point: Point { total }

    func hash(into hasher: inout Hasher) {

        hasher.combine(displayPeriod)
    }

    static func make(
        by pointOfDay: [PointOfDay],
        userId: String,
        userName: String,
        dateRange: ClosedRange<Date>,
        calendar: Calendar
    ) -> Self {

        let targetMonthPoints = pointOfDay.filter { dateRange.contains($0.indexedDay) }

        return .init(
            userId: userId,
            userName: userName,
            displayPeriod: .month,
            total: calcTotalPoint(targetMonthPoints),
            elements: .init(targetMonthPoints)
        )
    }

    /// 月毎に分けた月間ポイントのリスト
    static func makeWithSeparated(by pointOfDays: [PointOfDay], userId: String, userName: String, calendar: Calendar) -> [Self] {

        let separetedDic = pointOfDays.reduce([DateComponents: Set<PointOfDay>]()) { partialResult, pointOfDay in

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

        return separetedDic.map {
            .init(
                userId: userId,
                userName: userName,
                displayPeriod: .month,
                total: calcTotalPoint(.init($0.value)),
                elements: $0.value
            )
        }
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
