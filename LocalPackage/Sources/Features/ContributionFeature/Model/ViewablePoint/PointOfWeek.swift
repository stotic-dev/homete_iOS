//
//  PointOfWeek.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

struct PointOfWeek: Equatable, Hashable, ViewablePointElement, ViewablePointList<PointOfDay> {
    let displayPeriod: DisplayPointPeriod
    let total: Point
    let elements: Set<PointOfDay>

    var point: Point { total }

    init(displayPeriod: DisplayPointPeriod, elements: Set<PointOfDay>) {
        self.displayPeriod = displayPeriod
        self.total = elements.reduce(Point(value: .zero)) { partialResult, pointOfDay in
            .init(value: partialResult.value + pointOfDay.point.value)
        }
        self.elements = elements
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(displayPeriod)
    }

    static func make(period: DateComponents, by pointOfDays: [PointOfDay], calendar: Calendar) -> Self {
        let targetWeekPoints = pointOfDays.filter {
            weekComponent(pointOfDay: $0, calendar: calendar) == period
        }
        return .init(
            displayPeriod: .init(type: .week, components: period),
            elements: .init(targetWeekPoints)
        )
    }

    /// 週毎に分けた週間ポイントのリスト
    static func makeWithSeparated(by pointOfDays: [PointOfDay], calendar: Calendar) -> [Self] {
        return pointOfDays.reduce([Self]()) { partialResult, pointOfDay in
            let week = weekComponent(pointOfDay: pointOfDay, calendar: calendar)
            var result = partialResult

            if let lastWeek = partialResult.last,
               let lastIndex = partialResult.firstIndex(of: lastWeek),
               lastWeek.displayPeriod.components == week {
                var currentWeekElements = lastWeek.elements
                currentWeekElements.insert(pointOfDay)
                result[lastIndex] = .init(
                    displayPeriod: .init(type: .week, components: week),
                    elements: currentWeekElements
                )
            } else {
                result.append(Self(
                    displayPeriod: .init(type: .week, components: week),
                    elements: [pointOfDay]
                ))
            }

            return result
        }
    }
}

private extension PointOfWeek {

    static func weekComponent(pointOfDay: PointOfDay, calendar: Calendar) -> DateComponents {
        calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: pointOfDay.indexedDay)
    }
}
