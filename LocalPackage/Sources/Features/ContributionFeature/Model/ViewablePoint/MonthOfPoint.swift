//
//  MonthOfPoint.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

struct MonthOfPoint: Equatable, Hashable, ViewablePointElement, ViewablePointList<DayOfPoint> {
    let displayPeriod: DisplayPointPeriod
    let total: Point
    let elements: Set<DayOfPoint>
    
    var point: Point { total }
    
    init(displayPeriod: DisplayPointPeriod, elements: Set<DayOfPoint>) {
        self.displayPeriod = displayPeriod
        self.total = elements.reduce(Point(value: .zero), { partialResult, dayOfPoint in
            return .init(value: partialResult.value + dayOfPoint.point.value)
        })
        self.elements = elements
    }
    
    func hash(into hasher: inout Hasher) {
        
        hasher.combine(displayPeriod)
    }
    
    static func make(period: DateComponents, by pointOfDay: [DayOfPoint], calendar: Calendar) -> Self {

        let targetMonthPoints = pointOfDay.filter {
            monthComponent(pointOfDay: $0, calendar: calendar) == period
        }
        
        return .init(
            displayPeriod: .init(type: .month, components: period),
            elements: .init(targetMonthPoints)
        )
    }
    
    /// 月毎に分けた月間ポイントのリスト
    static func makeWithSeparated(by dayOfPoints: [DayOfPoint], calendar: Calendar) -> [Self] {
        
        return dayOfPoints.reduce([Self]()) { partialResult, dayOfPoint in
            let month = monthComponent(pointOfDay: dayOfPoint, calendar: calendar)
            var result = partialResult
            
            if let lastMonth = partialResult.last,
               let lastIndex = partialResult.firstIndex(of: lastMonth),
               lastMonth.displayPeriod.components == month {
                // 月の計算の続き
                var currentMonthElements = lastMonth.elements
                currentMonthElements.insert(dayOfPoint)
                result[lastIndex] = .init(
                    displayPeriod: .init(type: .month, components: month),
                    elements: currentMonthElements
                )
            } else {
                // それ以外はそのまま追加
                let pointOfMonth = Self(
                    displayPeriod: .init(type: .month, components: month),
                    elements: [dayOfPoint]
                )
                result.append(pointOfMonth)
            }
            
            return result
        }
    }
}

private extension MonthOfPoint {
    
    static func monthComponent(pointOfDay: DayOfPoint, calendar: Calendar) -> DateComponents {
        
        return calendar.dateComponents([.year, .month], from: pointOfDay.indexedDay)
    }
}
