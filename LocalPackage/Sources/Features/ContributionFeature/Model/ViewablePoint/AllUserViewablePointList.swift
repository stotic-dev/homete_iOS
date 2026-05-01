//
//  AllUserViewablePointList.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/01.
//

import Foundation

struct AllUserViewablePointList: Equatable {
    /// グラフに表示する日データ
    let list: [ViewablePointList]
    /// 表示区間
    let displayPeriod: DisplayPointPeriod.PeriodType
    /// グラフの時間軸を表す配列
    let xAxisDates: [Date]
    /// 表示対象の日付範囲
    let dateRange: ClosedRange<Date>

    static func make<T: GenerableViewablePointList>(
        list: [T],
        displayPeriod: DisplayPointPeriod.PeriodType,
        dateRange: ClosedRange<Date>,
        calendar: Calendar
    ) -> Self {
        return .init(
            list: list.map { $0.generate() },
            displayPeriod: displayPeriod,
            xAxisDates: calcXAxisDates(
                displayPeriod: displayPeriod,
                dateRange: dateRange,
                calendar: calendar
            ),
            dateRange: dateRange
        )
    }

    static func calcXAxisDates(
        displayPeriod: DisplayPointPeriod.PeriodType,
        dateRange: ClosedRange<Date>,
        calendar: Calendar
    ) -> [Date] {
        let (strideComponent, strideCount): (Calendar.Component, Int) = {
            switch displayPeriod {
            case .year: return (.month, 1)
            case .month: return (.day, 5)
            case .week: return (.day, 1)
            }
        }()
        let start = dateRange.lowerBound
        let end = dateRange.upperBound
        var dates: [Date] = []
        var current = start
        while current <= end {
            dates.append(current)
            guard let next = calendar.date(byAdding: strideComponent, value: strideCount, to: current) else { break }
            current = next
        }
        if let last = dates.last {
            switch displayPeriod {
            case .month, .week:
                if !calendar.isDate(last, inSameDayAs: end) {
                    dates.append(end)
                }
            case .year:
                if !calendar.isDate(last, equalTo: end, toGranularity: .month),
                   let monthStart = calendar.date(from: calendar.dateComponents([.era, .year, .month], from: end)) {
                    dates.append(monthStart)
                }
            }
        }
        return dates
    }
}
