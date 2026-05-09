//
//  PointOfDay.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

/// 一日のポイント
struct PointOfDay: Equatable, Hashable {
    let indexedDay: Date
    let point: Point
    let achievedCount: Int

    var date: Date { indexedDay }

    init(indexedDay: Date, point: Point, achievedCount: Int = 1) {
        self.indexedDay = indexedDay
        self.point = point
        self.achievedCount = achievedCount
    }
}

extension Sequence where Element == PointOfDay {
    
    /// ポイントと家事達成数の合計を返す
    func calcTotalValue() -> (Point, Int) {

        return self.reduce((Point(value: .zero), .zero), { partialResult, pointOfDay in
            
            let point = Point(value: partialResult.0.value + pointOfDay.point.value)
            let achievementCount = partialResult.1 + pointOfDay.achievedCount
            return (point, achievementCount)
        })
    }
}
