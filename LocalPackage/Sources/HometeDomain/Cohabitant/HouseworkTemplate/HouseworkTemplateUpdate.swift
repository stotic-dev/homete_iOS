//
//  HouseworkTemplateUpdate.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/09/26.
//

/// テンプレートの保存で書き込む内容
public struct HouseworkTemplateUpdate: Sendable, Equatable {

    /// 書き込む曜日定義（`Days`）
    public let days: [HouseworkTemplateDay]
    /// 追加・更新する毎月の家事（`MonthlyItems`）
    public let upsertedMonthlyItems: [HouseworkTemplateMonthlyItem]
    /// 削除する毎月の家事のID
    public let deletedMonthlyItemIds: [HouseworkTemplateItem.ItemId]

    public var isEmpty: Bool {
        days.isEmpty && upsertedMonthlyItems.isEmpty && deletedMonthlyItemIds.isEmpty
    }

    public init(
        days: [HouseworkTemplateDay] = [],
        upsertedMonthlyItems: [HouseworkTemplateMonthlyItem] = [],
        deletedMonthlyItemIds: [HouseworkTemplateItem.ItemId] = []
    ) {
        self.days = days
        self.upsertedMonthlyItems = upsertedMonthlyItems
        self.deletedMonthlyItemIds = deletedMonthlyItemIds
    }

}
