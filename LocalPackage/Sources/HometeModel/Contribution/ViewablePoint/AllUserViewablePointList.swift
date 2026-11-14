//
//  AllUserViewablePointList.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/01.
//

import Foundation

public struct AllUserViewablePointList: Equatable, Sendable {

    /// グラフに表示する日データ
    public let list: [ViewablePointList]
    /// 表示区間
    public let displayPeriod: DisplayPointPeriod.PeriodType

    public init(
        list: [ViewablePointList],
        displayPeriod: DisplayPointPeriod.PeriodType
    ) {
        self.list = list
        self.displayPeriod = displayPeriod
    }

    public static func make(
        list: [some GenerableViewablePointList],
        displayPeriod: DisplayPointPeriod.PeriodType
    ) -> Self {
        .init(
            list: list.map { $0.generate() },
            displayPeriod: displayPeriod
        )
    }

    /// 指定日のユーザー毎のポイント取得
    public func pointEntries(for date: Date, calendar: Calendar) -> [PointEntry] {
        list.compactMap { userData in
            guard let element = userData.elements.first(where: {
                calendar.isDate($0.date, equalTo: date, toGranularity: displayPeriod.granularity)
            }) else { return nil }
            return PointEntry(id: userData.userId, userName: userData.userName, point: element.point.value)
        }
    }

    /// タップ位置の日付に最も近い、データが存在する日付を返す
    public func nearestDate(to date: Date) -> Date? {
        list.flatMap { $0.elements.map(\.date) }
            .min { abs($0.timeIntervalSince(date)) < abs($1.timeIntervalSince(date)) }
    }

}
