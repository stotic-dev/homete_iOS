//
//  ApplyPlan.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/12.
//

import Foundation

/// 家事テンプレートを適用する際の計画。`now` から +6日（計7日）の範囲を対象に、
/// 既存の incomplete 家事と書き込み対象のテンプレート曜日を保持する。
public struct ApplyPlan: Equatable, Sendable {

    public let days: [HouseworkTemplateDay]
    public let cohabitantId: String
    public let targetDates: [Date]
    public let targetIncompleteItems: [HouseworkItem]
    public let calendar: Calendar

    public init(
        days: [HouseworkTemplateDay],
        cohabitantId: String,
        targetDates: [Date],
        targetIncompleteItems: [HouseworkItem],
        calendar: Calendar
    ) {
        self.days = days
        self.cohabitantId = cohabitantId
        self.targetDates = targetDates
        self.targetIncompleteItems = targetIncompleteItems
        self.calendar = calendar
    }

    /// 適用範囲（now〜+6日）と incomplete 家事の突き合わせから ApplyPlan を生成する
    public static func make(
        days: [HouseworkTemplateDay],
        cohabitantId: String,
        incompleteItems: [HouseworkItem],
        now: Date,
        calendar: Calendar
    ) -> Self {
        let targetDates = (0 ... 6).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))
        }
        let targetIndexedDates = targetDates.map {
            HouseworkIndexedDate(value: $0)
        }
        let targetIncompleteItems = incompleteItems.filter { item in
            targetIndexedDates.contains(item.indexedDate)
        }
        return .init(
            days: days,
            cohabitantId: cohabitantId,
            targetDates: targetDates,
            targetIncompleteItems: targetIncompleteItems,
            calendar: calendar
        )
    }

    /// 適用範囲内に incomplete 家事があり、上書き確認が必要かどうか
    public var requiresOverwriteConfirmation: Bool {
        !targetIncompleteItems.isEmpty
    }

    /// テンプレートから生成する新規家事アイテムの一覧
    public func makeNewItems(idGenerator: () -> String) -> [HouseworkItem] {
        var newItems: [HouseworkItem] = []
        for date in targetDates {
            let weekday = calendar.component(.weekday, from: date)
            let dayOfWeek = weekday - 1
            guard let templateDay = days.first(where: { $0.dayOfWeek == dayOfWeek }) else {
                continue
            }
            let metaData = DailyHouseworkMetaData(selectedDate: date, calendar: calendar)
            for templateItem in templateDay.items {
                newItems.append(
                    HouseworkItem(
                        id: idGenerator(),
                        title: templateItem.title,
                        point: templateItem.point,
                        metaData: metaData
                    )
                )
            }
        }
        return newItems
    }

}
