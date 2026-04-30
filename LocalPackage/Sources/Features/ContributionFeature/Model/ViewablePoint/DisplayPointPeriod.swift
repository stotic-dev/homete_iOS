//
//  DisplayPointPeriod.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

struct DisplayPointPeriod: Equatable, Hashable {
    let type: PeriodType
    let anchor: Date
    
    func calcDateRange(calendar: Calendar) -> ClosedRange<Date>? {
        guard let startOfMonth = calendar.date(
            byAdding: type.component,
            value: -1, to: anchor
        ) else { return nil }
        let endOfMonth = anchor
        return startOfMonth...endOfMonth
    }

    enum PeriodType {
        /// 週
        case week
        /// 月
        case month
        /// 年
        case year
        
        var component: Calendar.Component {
            switch self {
            case .week: .weekOfMonth
            case .month: .month
            case .year: .year
            }
        }
    }
}
