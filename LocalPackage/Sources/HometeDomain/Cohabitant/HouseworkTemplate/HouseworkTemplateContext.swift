//
//  HouseworkTemplateContext.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/14.
//

import Foundation

public struct HouseworkTemplateContext {

    public let metadata: HouseworkTemplateMeta?
    public let houseworkTemplate: [HouseworkTemplateDay]
    public let monthlyItems: [HouseworkTemplateMonthlyItem]

    /// テンプレートが設定されているかどうか
    public var hasTemplate: Bool {
        metadata != nil
    }

    public init(
        metadata: HouseworkTemplateMeta?,
        houseworkTemplate: [HouseworkTemplateDay],
        monthlyItems: [HouseworkTemplateMonthlyItem] = []
    ) {
        self.metadata = metadata
        self.houseworkTemplate = houseworkTemplate
        self.monthlyItems = monthlyItems
    }

    /// 指定日付に表示するテンプレートを返す
    ///
    /// その曜日の毎週の家事に、その日付に当てはまる毎月の家事を加えて返す。どちらも無い場合は`nil`。
    public func templateOfDay(by date: Date, calendar: Calendar) -> HouseworkTemplateDay? {
        guard let dayOfWeek = DayOfWeek.of(date: date, calendar: calendar) else { return nil }
        let weeklyTemplate = houseworkTemplate.first { $0.dayOfWeek == dayOfWeek }
        let monthlyTemplateItems = monthlyItems
            .filter { $0.rule.matches(date, calendar: calendar) }
            .map(\.item)

        guard !monthlyTemplateItems.isEmpty else { return weeklyTemplate }
        return .init(dayOfWeek: dayOfWeek, items: (weeklyTemplate?.items ?? []) + monthlyTemplateItems)
    }

}
