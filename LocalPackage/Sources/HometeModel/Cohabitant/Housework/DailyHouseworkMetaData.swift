//
//  DailyHouseworkMetaData.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/08.
//

import Foundation

public struct DailyHouseworkMetaData: Equatable, Sendable {

    public let indexedDate: HouseworkIndexedDate
    public let expiredAt: Date

    public init(indexedDate: HouseworkIndexedDate, expiredAt: Date) {
        self.indexedDate = indexedDate
        self.expiredAt = expiredAt
    }

}

public extension DailyHouseworkMetaData {

    /// 家事を新規登録する際のメタデータを生成する
    /// - Parameter storagePolicy: 保持期限の算出に使う保存期間ポリシー
    init(selectedDate: Date, calendar: Calendar, storagePolicy: HouseworkStoragePolicy) {
        let selectedDay = calendar.startOfDay(for: selectedDate)
        let indexedDate = HouseworkIndexedDate(value: selectedDay)
        self.init(
            indexedDate: indexedDate,
            expiredAt: storagePolicy.expiredAt(from: selectedDay, calendar: calendar)
        )
    }

}
