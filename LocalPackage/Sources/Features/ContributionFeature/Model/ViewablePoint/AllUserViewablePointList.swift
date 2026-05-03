//
//  AllUserViewablePointList.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/01.
//

import Foundation

struct AllUserViewablePointList: Equatable {

    struct PointEntry: Identifiable {
        let id: String
        let userName: String
        let point: Int
    }

    struct CumulativePointEntry: Identifiable, Equatable {
        let id: String
        let userName: String
        let date: Date
        let cumulativePoint: Int
    }

    /// グラフに表示する日データ
    let list: [ViewablePointList]
    /// 表示区間
    let displayPeriod: DisplayPointPeriod.PeriodType
    /// グラフの時間軸を表す配列
    let xAxisDates: [Date]
    /// 表示対象の日付範囲
    let dateRange: ClosedRange<Date>
    /// ユーザーごとの累計ポイント推移
    let cumulativeEntries: [CumulativePointEntry]

    static func make<T: GenerableViewablePointList>(
        list: [T],
        displayPeriod: DisplayPointPeriod.PeriodType,
        dateRange: ClosedRange<Date>,
        calendar: Calendar
    ) -> Self {
        let viewableList = list.map { $0.generate() }
        return .init(
            list: viewableList,
            displayPeriod: displayPeriod,
            xAxisDates: calcXAxisDates(
                displayPeriod: displayPeriod,
                dateRange: dateRange,
                calendar: calendar
            ),
            dateRange: dateRange,
            cumulativeEntries: calcCumulativeEntries(list: viewableList)
        )
    }

    private static func calcCumulativeEntries(list: [ViewablePointList]) -> [CumulativePointEntry] {
        list.flatMap { userData in
            let sorted = userData.elements.sorted { $0.date < $1.date }
            var running = 0
            return sorted.map { element in
                running += element.point.value
                return CumulativePointEntry(
                    id: "\(userData.userId)-\(element.date.timeIntervalSince1970)",
                    userName: userData.userName,
                    date: element.date,
                    cumulativePoint: running
                )
            }
        }
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
        if strideCount > 1, !dates.contains(end) {
            dates.append(end)
        }
        
        print("calcXAxisDates: dateRange(\(dateRange)) result(\(dates))")
        return dates
    }

    func pointEntries(for date: Date, calendar: Calendar) -> [PointEntry] {
        let granularity: Calendar.Component = switch displayPeriod {
        case .year: .month
        case .month, .week: .day
        }
        return list.compactMap { userData in
            guard let element = userData.elements.first(where: {
                calendar.isDate($0.date, equalTo: date, toGranularity: granularity)
            }) else { return nil }
            return PointEntry(id: userData.userId, userName: userData.userName, point: element.point.value)
        }
    }

    func cumulativeEntries(for date: Date, calendar: Calendar) -> [CumulativePointEntry] {
        let granularity: Calendar.Component = switch displayPeriod {
        case .year: .month
        case .month, .week: .day
        }
        return cumulativeEntries.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: granularity)
        }
    }
}
