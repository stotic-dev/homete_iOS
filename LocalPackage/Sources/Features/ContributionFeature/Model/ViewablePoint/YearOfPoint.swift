//
//  YearOfPoint.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

struct YearOfPoint: Equatable, Hashable, ViewablePointList<MonthOfPoint> {
    
    let displayPeriod: DisplayPointPeriod
    let total: Point
    let elements: Set<MonthOfPoint>
    
    func hash(into hasher: inout Hasher) {
        
        hasher.combine(displayPeriod)
    }
    
    static func make(util: DisplayPointPeriod, by dayOfPoints: [DayOfPoint]) -> Self {
        
        guard case .year(let yearValue) = util else {
            preconditionFailure("Unexpected display period: \(util).")
        }

        let targetYearPoints = dayOfPoints.filter {
            $0.indexedDay.components(separatedBy: "/").first == yearValue
        }
        let months = MonthOfPoint.makeWithSeparated(by: targetYearPoints)
        let total = months.reduce(Point(value: .zero)) { partialResult, pointOfMonth in
            return .init(value: partialResult.value + pointOfMonth.total.value)
        }
        
        return .init(displayPeriod: util, total: total, elements: .init(months))
    }
}
