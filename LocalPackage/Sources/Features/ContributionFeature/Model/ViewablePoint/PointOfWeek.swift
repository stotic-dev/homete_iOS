//
//  PointOfWeek.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

struct PointOfWeek: Equatable, Hashable {

    let userId: String
    let userName: String
    let total: Point
    let elements: Set<PointOfDay>
    let startDate: Date

    var point: Point { total }
    var date: Date { startDate }

    func hash(into hasher: inout Hasher) {
        hasher.combine(startDate)
    }

    static func make(
        by pointOfDays: [PointOfDay],
        userId: String,
        userName: String,
        dates: [Date],
        calendar: Calendar
    ) -> Self {

        let allDays: [PointOfDay] = dates.map { targetDate in
            pointOfDays.first {
                calendar.isDate($0.indexedDay, inSameDayAs: targetDate)
            } ?? .init(indexedDay: targetDate, point: .init(value: .zero))
        }
        return .init(
            userId: userId,
            userName: userName,
            total: calcTotalPoint(allDays),
            elements: .init(allDays),
            startDate: dates.first ?? Date()
        )
    }
}

extension PointOfWeek: GenerableViewablePointList {
    
    func generate() -> ViewablePointList {
        
        return .init(
            userId: userId,
            userName: userName,
            total: total,
            elements: .init(elements.map { .init(point: $0.point, date: $0.indexedDay) })
        )
    }
}

private extension PointOfWeek {

    static func calcTotalPoint(_ pointOfDay: [PointOfDay]) -> Point {

        return pointOfDay.reduce(Point(value: .zero), { partialResult, pointOfDay in
            return .init(value: partialResult.value + pointOfDay.point.value)
        })
    }
}
