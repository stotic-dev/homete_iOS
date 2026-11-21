//
//  PointOfDay.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

/// 一日のポイント
public struct PointOfDay: Equatable, Hashable, Sendable {

    public let indexedDay: Date
    public let point: Point
    public let achievedCount: Int

    public var date: Date {
        indexedDay
    }

    public init(indexedDay: Date, point: Point, achievedCount: Int = 1) {
        self.indexedDay = indexedDay
        self.point = point
        self.achievedCount = achievedCount
    }

}

public extension Sequence<PointOfDay> {

    /// ポイントと家事達成数の合計を返す
    func calcTotalValue() -> (Point, Int) {
        reduce((Point(value: .zero), .zero)) { partialResult, pointOfDay in
            let point = Point(value: partialResult.0.value + pointOfDay.point.value)
            let achievementCount = partialResult.1 + pointOfDay.achievedCount
            return (point, achievementCount)
        }
    }

}
