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

    var date: Date { indexedDay }

    func hash(into hasher: inout Hasher) {
        hasher.combine(indexedDay)
    }
}
