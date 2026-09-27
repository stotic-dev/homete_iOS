//
//  StoredAllHouseworkList.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/11/16.
//

import Foundation

public struct StoredAllHouseworkList: Equatable, Sendable {

    public private(set) var value: [DailyHouseworkList]

    public init(value: [DailyHouseworkList]) {
        self.value = value
    }

    public static func makeMultiDateList(
        items: [HouseworkItem],
        anchorDate: Date,
        offsetDays: Int,
        calendar: Calendar
    ) -> Self {
        let targetDates = Set(
            HouseworkIndexedDate.calcTargetPeriod(anchorDate: anchorDate, offsetDays: offsetDays, calendar: calendar)
        )
        // 家事を操作するたびに並びが入れ替わらないよう、作った順に並べておく
        let dailyLists: [DailyHouseworkList] = Dictionary(
            grouping: items
                .filter { targetDates.contains($0.indexedDate.value) }
                .sorted(by: isCreatedBefore)
        ) { $0.indexedDate }
            .compactMap {
                guard let firstItem = $1.first else { return nil }
                return .init(
                    items: $1,
                    metaData: .init(indexedDate: firstItem.indexedDate, expiredAt: firstItem.expiredAt)
                )
            }
        return .init(value: dailyLists)
    }

    public func item(_ item: HouseworkItem) -> HouseworkItem? {
        guard let targetDayList = value.first(
            where: { $0.metaData.indexedDate == item.indexedDate }
        ),
            let targetItem = targetDayList.items.first(where: { $0.id == item.id }) else { return nil }
        return targetItem
    }

    public mutating func removeAll() {
        value = []
    }

}

private extension StoredAllHouseworkList {

    /// 作成日時の古い順。作成日時を持たない家事は、記録を始める前に作られたものなので先頭に置く
    ///
    /// 作成日時が同じ家事や、どちらも持たない家事はIDで並べ、端末や起動をまたいでも同じ並びにする。
    static func isCreatedBefore(_ lhs: HouseworkItem, _ rhs: HouseworkItem) -> Bool {
        (lhs.createdAt ?? .distantPast, lhs.id) < (rhs.createdAt ?? .distantPast, rhs.id)
    }

}
