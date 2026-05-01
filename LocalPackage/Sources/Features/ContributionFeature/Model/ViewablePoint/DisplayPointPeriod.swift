//
//  DisplayPointPeriod.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

struct DisplayPointPeriod: Equatable, Hashable {
    var type: PeriodType
    let anchor: Date
    
    func calcDateRange(calendar: Calendar) -> ClosedRange<Date>? {
        guard let decreasedDate = calendar.date(
            byAdding: type.component,
            value: -1,
            to: anchor
        ),
              let start = calendar.date(byAdding: .day, value: 1, to: decreasedDate) else { return nil }
        let end = anchor
        return start...end
    }
    
    func shiftPeriod(by value: Int, calendar: Calendar) -> Self {
        
        guard let newAnchor = calendar.date(
            byAdding: type.component,
            value: value,
            to: anchor
        ) else { return self }
        return .init(type: type, anchor: newAnchor)
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
