//
//  AllUserCumulativeData.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/07.
//

import Foundation

struct AllUserCumulativeData: Equatable {

    /// グラフに表示する累積データ
    let list: [ViewablePointList]
    /// 表示区間
    let displayPeriod: DisplayPointPeriod.PeriodType

    static func make(
        list: [ViewablePointList],
        displayPeriod: DisplayPointPeriod.PeriodType
    ) -> Self {
        let cumulativeList: [ViewablePointList] = list.map { userData in
            var running = 0
            let cumulatedList: [ViewablePointElement] = userData.sortedElements.map {
                running += $0.point.value
                return .init(point: .init(value: running), date: $0.date)
            }
            return .init(
                userId: userData.userId,
                userName: userData.userName,
                total: .init(value: running),
                elements: .init(cumulatedList)
            )
        }

        print("cumulativeList: \(cumulativeList)")
        return .init(
            list: cumulativeList,
            displayPeriod: displayPeriod
        )
    }

    /// 指定日時点でのユーザー毎の取得ポイント累計
    func cumulativePointEntries(for date: Date, calendar: Calendar) -> [PointEntry] {
        list.flatMap { userData in
            let filtered = userData.elements.filter {
                calendar.isDate($0.date, equalTo: date, toGranularity: displayPeriod.granularity)
            }
            let sorted = filtered.sorted { $0.date < $1.date }
            var running = 0
            return sorted.map { element in
                running += element.point.value
                return PointEntry(
                    id: userData.userId,
                    userName: userData.userName,
                    point: running
                )
            }
        }
    }

    /// タップ位置の日付に最も近い、データが存在する日付を返す
    func nearestDate(to date: Date) -> Date? {
        list.flatMap { $0.elements.map(\.date) }
            .min { abs($0.timeIntervalSince(date)) < abs($1.timeIntervalSince(date)) }
    }

}
