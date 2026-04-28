//
//  DisplayPointPeriod.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

struct DisplayPointPeriod: Equatable, Hashable {
    let type: PeriodType
    let components: DateComponents

    enum PeriodType {
        /// 週
        case week
        /// 月
        case month
        /// 年
        case year
    }
}
