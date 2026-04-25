//
//  PointOfMonth.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

struct PointOfMonth: Equatable, Hashable, ViewablePointElement, ViewablePointList<PointOfDay> {
    let displayPeriod: DisplayPointPeriod
    let total: Point
    let elements: Set<PointOfDay>
    
    var point: Point { total }
    
    init(displayPeriod: DisplayPointPeriod, elements: Set<PointOfDay>) {
        self.displayPeriod = displayPeriod
        self.total = elements.reduce(Point(value: .zero), { partialResult, pointOfDay in
            return .init(value: partialResult.value + pointOfDay.point.value)
        })
        self.elements = elements
    }
    
    func hash(into hasher: inout Hasher) {
        
        hasher.combine(displayPeriod)
    }
    
    static func make(period: DateComponents, by pointOfDay: [PointOfDay], calendar: Calendar) -> Self {

        let targetMonthPoints = pointOfDay.filter {
            monthComponent(pointOfDay: $0, calendar: calendar) == period
        }
        
        return .init(
            displayPeriod: .init(type: .month, components: period),
            elements: .init(targetMonthPoints)
        )
    }
    
    /// 月毎に分けた月間ポイントのリスト
    static func makeWithSeparated(by pointOfDays: [PointOfDay], calendar: Calendar) -> [Self] {
        
        return pointOfDays.reduce([Self]()) { partialResult, pointOfDay in
            let month = monthComponent(pointOfDay: pointOfDay, calendar: calendar)
            var result = partialResult
            
            if let lastMonth = partialResult.last,
               let lastIndex = partialResult.firstIndex(of: lastMonth),
               lastMonth.displayPeriod.components == month {
                // 月の計算の続き
                var currentMonthElements = lastMonth.elements
                currentMonthElements.insert(pointOfDay)
                result[lastIndex] = .init(
                    displayPeriod: .init(type: .month, components: month),
                    elements: currentMonthElements
                )
            } else {
                // それ以外はそのまま追加
                let pointOfMonth = Self(
                    displayPeriod: .init(type: .month, components: month),
                    elements: [pointOfDay]
                )
                result.append(pointOfMonth)
            }
            
            return result
        }
    }
}

private extension PointOfMonth {
    
    static func monthComponent(pointOfDay: PointOfDay, calendar: Calendar) -> DateComponents {
        
        return calendar.dateComponents([.year, .month], from: pointOfDay.indexedDay)
    }
}
