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

    static func make<T: GenerableViewablePointList>(
        list: [T],
        displayPeriod: DisplayPointPeriod.PeriodType
    ) -> Self {
        
        return .init(
            list: list.map { $0.generate() },
            displayPeriod: displayPeriod
        )
    }
    
    /// 指定日のユーザー毎のポイント取得
    func pointEntries(for date: Date, calendar: Calendar) -> [PointEntry] {
        
        return list.compactMap { userData in
            guard let element = userData.elements.first(where: {
                calendar.isDate($0.date, equalTo: date, toGranularity: displayPeriod.granularity)
            }) else { return nil }
            return PointEntry(id: userData.userId, userName: userData.userName, point: element.point.value)
        }
    }
    
    /// タップ位置の日付に最も近い、データが存在する日付を返す
    func nearestDate(to date: Date) -> Date? {
        
        return list.flatMap { $0.elements.map(\.date) }
            .min { abs($0.timeIntervalSince(date)) < abs($1.timeIntervalSince(date)) }
    }
}
