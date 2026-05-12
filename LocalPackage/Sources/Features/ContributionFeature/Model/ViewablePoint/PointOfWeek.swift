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
    let totalAchievementCount: Int
    let elements: Set<PointOfDay>
    let startDate: Date

    var point: Point {
        total
    }

    var date: Date {
        startDate
    }

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
        let (totalPoint, totalAchievementCount) = allDays.calcTotalValue()
        return .init(
            userId: userId,
            userName: userName,
            total: totalPoint,
            totalAchievementCount: totalAchievementCount,
            elements: .init(allDays),
            startDate: dates.first ?? Date()
        )
    }

}

extension PointOfWeek: GenerableViewablePointList {

    func generate() -> ViewablePointList {
        .init(
            userId: userId,
            userName: userName,
            total: total,
            elements: .init(elements.map { .init(point: $0.point, date: $0.indexedDay) })
        )
    }

}
