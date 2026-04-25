//
//  DayOfPoint.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

/// 一日のポイント
struct DayOfPoint: Equatable, Hashable, ViewablePointElement {
    let indexedDay: Date
    let point: Point
    
    init(indexedDay: Date, point: Point) {
        self.indexedDay = indexedDay
        self.point = point
    }
    
    // 日付基準で一意にする
    func hash(into hasher: inout Hasher) {
        hasher.combine(indexedDay)
    }
}
