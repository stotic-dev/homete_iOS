//
//  PointOfYear.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

public struct PointOfYear: Equatable, Hashable, Sendable {

    public let userId: String
    public let userName: String
    public let total: Point
    public let totalAchievementCount: Int
    public let elements: Set<PointOfMonth>

    public init(
        userId: String,
        userName: String,
        total: Point,
        totalAchievementCount: Int,
        elements: Set<PointOfMonth>
    ) {
        self.userId = userId
        self.userName = userName
        self.total = total
        self.totalAchievementCount = totalAchievementCount
        self.elements = elements
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
    }

    public static func make(
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
                    totalAchievementCount: .zero,
                    elements: [],
                    startDate: startOfMonth
                )
            }
            return month
        }

        let (totalPoint, totalAchievementCount) = allMonths.calcTotalValue()

        return .init(
            userId: userId,
            userName: userName,
            total: totalPoint,
            totalAchievementCount: totalAchievementCount,
            elements: .init(allMonths)
        )
    }

}

extension PointOfYear: GenerableViewablePointList {

    public func generate() -> ViewablePointList {
        .init(
            userId: userId,
            userName: userName,
            total: total,
            elements: .init(elements.map { .init(point: $0.total, date: $0.startDate) })
        )
    }

}
