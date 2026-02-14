//
//  DailyHouseworkList.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/08.
//

import Foundation

public struct DailyHouseworkList: Equatable, Sendable {

    public let items: [HouseworkItem]
    public let metaData: DailyHouseworkMetaData

    public static func makeInitialValue(
        selectedDate: Date,
        items: [HouseworkItem],
        calendar: Calendar
    ) -> Self {

        return .init(
            items: items,
            metaData: .init(selectedDate: selectedDate, calendar: calendar)
        )
    }

    /// この日付の家事情報がすでに登録済みであること
    public var isRegistered: Bool { !items.isEmpty }

    /// すでに同じ家事が登録されているかどうか
    public func isAlreadyRegistered(_ item: HouseworkItem) -> Bool {

        return items.contains { $0.title == item.title }
    }

    public init(items: [HouseworkItem], metaData: DailyHouseworkMetaData) {
        self.items = items
        self.metaData = metaData
    }
}
