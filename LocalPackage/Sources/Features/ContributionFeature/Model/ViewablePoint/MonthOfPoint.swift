//
//  MonthOfPoint.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

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
    
    static func make(util: DisplayPointPeriod, by pointOfDay: [DayOfPoint]) -> Self {
        
        guard case .month(let monthValue) = util else {
            preconditionFailure("Unexpected display period: \(util).")
        }

        let targetMonthPoints = pointOfDay.filter {
            indexedMonth(pointOfDay: $0) == monthValue
        }
        
        return .init(displayPeriod: util, elements: .init(targetMonthPoints))
    }
    
    /// 月毎に分けた月間ポイントのリスト
    static func makeWithSeparated(by dayOfPoints: [DayOfPoint]) -> [Self] {
        
        return dayOfPoints.reduce([Self]()) { partialResult, dayOfPoint in
            let month = indexedMonth(pointOfDay: dayOfPoint)
            var result = partialResult
            
            if let lastMonth = partialResult.last,
               let lastIndex = partialResult.firstIndex(of: lastMonth),
               lastMonth.displayPeriod == .month(value: month) {
                // 月の計算の続き
                var currentMonthElements = lastMonth.elements
                currentMonthElements.insert(dayOfPoint)
                result[lastIndex] = .init(displayPeriod: .month(value: month), elements: currentMonthElements)
            } else {
                // それ以外はそのまま追加
                let pointOfMonth = Self(displayPeriod: .month(value: month), elements: [dayOfPoint])
                result.append(pointOfMonth)
            }
            
            return result
        }
    }
}

private extension MonthOfPoint {
    static func indexedMonth(pointOfDay: DayOfPoint) -> String {
        return pointOfDay.indexedDay.components(separatedBy: "/").prefix(2).joined(separator: "/")
    }
}
