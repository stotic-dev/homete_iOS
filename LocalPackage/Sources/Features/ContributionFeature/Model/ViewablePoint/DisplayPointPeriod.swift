//
//  DisplayPointPeriod.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

enum DisplayPointPeriod: Equatable, Hashable {
    /// 週
    case week(value: String)
    /// 月
    case month(value: String)
    /// 年
    case year(value: String)
}
