//
//  DailyHouseworkMetaData.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/08.
//

import Foundation

public struct DailyHouseworkMetaData: Equatable, Sendable {

    public let indexedDate: HouseworkIndexedDate

    public init(indexedDate: HouseworkIndexedDate) {
        self.indexedDate = indexedDate
    }

}

public extension DailyHouseworkMetaData {

    /// 家事を新規登録する際のメタデータを生成する
    init(selectedDate: Date, calendar: Calendar) {
        self.init(indexedDate: HouseworkIndexedDate(value: calendar.startOfDay(for: selectedDate)))
    }

}
