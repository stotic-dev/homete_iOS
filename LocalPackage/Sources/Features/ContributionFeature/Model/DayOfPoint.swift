//
//  DayOfPoint.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

/// 一日のポイント
struct DayOfPoint: Equatable, Hashable, ViewablePointElement {
    let indexedDay: String
    let point: Point
    
    init(indexedDay: String, point: Point) {
        self.indexedDay = indexedDay
        self.point = point
    }
    
    // 日付基準で一意にする
    func hash(into hasher: inout Hasher) {
        hasher.combine(indexedDay)
    }
}
