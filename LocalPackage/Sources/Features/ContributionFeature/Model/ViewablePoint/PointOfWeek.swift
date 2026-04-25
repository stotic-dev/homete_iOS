//
//  PointOfWeek.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

struct PointOfWeek: Equatable, Hashable, ViewablePointElement, ViewablePointList<PointOfDay> {
    
    let userId: String
    let displayPeriod: DisplayPointPeriod
    let total: Point
    let elements: Set<PointOfDay>

    var point: Point { total }

    func hash(into hasher: inout Hasher) {
        hasher.combine(displayPeriod)
    }

    static func make(
        by pointOfDays: [PointOfDay],
        userId: String,
        period: DateComponents,
        calendar: Calendar
    ) -> Self {
        
        let targetWeekPoints = pointOfDays.filter {
            weekComponent(pointOfDay: $0, calendar: calendar) == period
        }
        return .init(
            userId: userId,
            displayPeriod: .init(type: .week, components: period),
            total: calcTotalPoint(targetWeekPoints),
            elements: .init(targetWeekPoints)
        )
    }
}

private extension PointOfWeek {

    static func weekComponent(pointOfDay: PointOfDay, calendar: Calendar) -> DateComponents {
        
        return calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: pointOfDay.indexedDay)
    }
    
    static func calcTotalPoint(_ pointOfDay: [PointOfDay]) -> Point {
        
        return pointOfDay.reduce(Point(value: .zero), { partialResult, pointOfDay in
            return .init(value: partialResult.value + pointOfDay.point.value)
        })
    }
}
