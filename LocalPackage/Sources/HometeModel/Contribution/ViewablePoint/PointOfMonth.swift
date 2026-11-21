//
//  PointOfMonth.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

public struct PointOfMonth: Equatable, Hashable, Sendable {

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

        let (totalPoint, totalAchivementCount) = allDays.calcTotalValue()

        return .init(
            userId: userId,
            userName: userName,
            total: totalPoint,
            totalAchievementCount: totalAchivementCount,
            elements: .init(allDays),
            startDate: dates.first ?? Date()
        )
    }

    /// 月毎に分けた月間ポイントのリスト
    public static func makeWithSeparated(
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
            let (totalPoint, totalAchivementCount) = Array(elements).calcTotalValue()
            return .init(
                userId: userId,
                userName: userName,
                total: totalPoint,
                totalAchievementCount: totalAchivementCount,
                elements: elements,
                startDate: startDate
            )
        }
    }

}

extension PointOfMonth: GenerableViewablePointList {

    public func generate() -> ViewablePointList {
        .init(
            userId: userId,
            userName: userName,
            total: total,
            elements: .init(elements.map { .init(point: $0.point, date: $0.indexedDay) })
        )
    }

}

private extension PointOfMonth {

    static func monthComponent(pointOfDay: PointOfDay, calendar: Calendar) -> DateComponents {
        calendar.dateComponents([.year, .month], from: pointOfDay.indexedDay)
    }

}

public extension Sequence<PointOfMonth> {

    /// ポイントと家事達成数の合計を返す
    func calcTotalValue() -> (Point, Int) {
        reduce((Point(value: .zero), .zero)) { partialResult, monthOfDay in
            let point = Point(value: partialResult.0.value + monthOfDay.total.value)
            let achievementCount = partialResult.1 + monthOfDay.totalAchievementCount
            return (point, achievementCount)
        }
    }

}
