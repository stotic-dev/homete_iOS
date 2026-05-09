//
//  DisplayPointPeriod.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

struct DisplayPointPeriod: Equatable, Hashable {
    /// 表示期間の種別
    var type: PeriodType
    /// 表示期間の基準日
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

    /// グラフにプロットする粒度としてDateの配列を返す
    func calcDatePeriod(calendar: Calendar) -> [Date] {
        
        var dates: [Date] = []
        guard let range: ClosedRange<Date> = calcDateRange(calendar: calendar) else {
            return []
        }
        var current = calendar.startOfDay(for: range.lowerBound)

        while current <= calendar.startOfDay(for: range.upperBound) {
            dates.append(current)

            guard let next = calendar.date(
                byAdding: type.granularity,
                value: 1,
                to: current
            ) else {
                break
            }

            current = calendar.startOfDay(for: next)
        }

        return dates
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
        
        /// 対応する期間の範囲
        var component: Calendar.Component {
            switch self {
            case .week: .weekOfMonth
            case .month: .month
            case .year: .year
            }
        }
        
        /// 期間内のデータの粒度
        var granularity: Calendar.Component {
            switch self {
            case .year: .month
            case .month, .week: .day
            }
        }
    }
}
