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
