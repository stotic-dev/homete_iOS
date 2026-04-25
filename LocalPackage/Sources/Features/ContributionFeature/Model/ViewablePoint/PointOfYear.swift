//
//  PointOfYear.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

struct PointOfYear: Equatable, Hashable, ViewablePointList<PointOfMonth> {
    
    let displayPeriod: DisplayPointPeriod
    let total: Point
    let elements: Set<PointOfMonth>
    
    func hash(into hasher: inout Hasher) {
        
        hasher.combine(displayPeriod)
    }
    
    static func make(period: DateComponents, by dayOfPoints: [PointOfDay], calendar: Calendar) -> Self {
        
        let targetYearPoints = dayOfPoints.filter {
            calendar.dateComponents([.year], from: $0.indexedDay) == period
        }
        let months = PointOfMonth.makeWithSeparated(by: targetYearPoints, calendar: calendar)
        let total = months.reduce(Point(value: .zero)) { partialResult, pointOfMonth in
            return .init(value: partialResult.value + pointOfMonth.total.value)
        }
        
        return .init(
            displayPeriod: .init(type: .year, components: period),
            total: total,
            elements: .init(months)
        )
    }
}
