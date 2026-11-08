//
//  PointOfWeek.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

public struct PointOfWeek: Equatable, Hashable, Sendable {

    public let userId: String
    public let userName: String
    public let total: Point
    public let totalAchievementCount: Int
    public let elements: Set<PointOfDay>
    public let startDate: Date

    public init(
        userId: String,
        userName: String,
        total: Point,
        totalAchievementCount: Int,
        elements: Set<PointOfDay>,
        startDate: Date
    ) {
        self.userId = userId
        self.userName = userName
        self.total = total
        self.totalAchievementCount = totalAchievementCount
        self.elements = elements
        self.startDate = startDate
    }

    public var point: Point {
        total
    }

    public var date: Date {
        startDate
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
        hasher.combine(startDate)
    }

    public static func make(
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

    public func generate() -> ViewablePointList {
        .init(
            userId: userId,
            userName: userName,
            total: total,
            elements: .init(elements.map { .init(point: $0.point, date: $0.indexedDay) })
        )
    }

}
