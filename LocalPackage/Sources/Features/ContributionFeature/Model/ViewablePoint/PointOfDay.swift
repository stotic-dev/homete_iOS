//
//  PointOfDay.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

/// 一日のポイント
struct PointOfDay: Equatable, Hashable, ViewablePointElement {
    let indexedDay: Date
    let point: Point

    func hash(into hasher: inout Hasher) {
        hasher.combine(indexedDay)
    }
}
