//
//  WeekOfPoint.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

struct WeekOfPoint: Equatable, Hashable, ViewablePointElement, ViewablePointList<DayOfPoint> {
    let displayPeriod: DisplayPointPeriod
    let total: Point
    let elements: Set<DayOfPoint>
    
    var point: Point { total }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(displayPeriod)
    }
    
    // TODO: HouseworkItemのindexedDateがDateじゃないと実装できないやつ
//    static func make(util: DisplayPointPeriod, by pointOfDay: [DayOfPoint]) -> Self {
//        
//        guard case .week(let weekValue) = util else {
//            preconditionFailure("Unexpected display period: \(util).")
//        }
//
//        let targetMonthPoints = pointOfDay.filter {
//            indexedMonth(pointOfDay: $0) == monthValue
//        }
//        
//        return .init(displayPeriod: util, elements: .init(targetMonthPoints))
//    }
}
