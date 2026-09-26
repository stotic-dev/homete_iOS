//
//  HouseworkTemplateDraft.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/16.
//

import Foundation
import HometeDomain

/// 家事テンプレート編集中の状態を表すモデル。曜日別のアイテム集合と毎月の家事を保持し、編集操作を提供する。
struct HouseworkTemplateDraft: Equatable {

    private(set) var days: [DayOfWeek: [HouseworkTemplateItem]]
    /// 毎月の家事。常に表示順（同じルールならID順）に並べておく
    /// - Note: Firestoreから読んだ順（ドキュメントID順）と編集で追加した順が違っても、
    ///         並び順だけの違いを「未保存の変更」やコンフリクトと判定しないため
    private(set) var monthlyItems: [HouseworkTemplateMonthlyItem]

    /// 保存するテンプレートのモデルを返す
    var saveDays: [HouseworkTemplateDay] {
        days.map { .init(dayOfWeek: $0.key, items: $0.value) }
    }

    /// 毎月の家事を表示順（`MonthlyRecurrenceRule.isOrderedBefore`）に並べて返す
    var displayedMonthlyItems: [HouseworkTemplateMonthlyItem] {
        monthlyItems
    }

    init(
        days: [DayOfWeek: [HouseworkTemplateItem]] = [:],
        monthlyItems: [HouseworkTemplateMonthlyItem] = []
    ) {
        self.days = days
        self.monthlyItems = Self.sortedForDisplay(monthlyItems)
    }

    /// 入力されたテンプレートから編集用のモデルを生成
    static func make(
        _ template: [HouseworkTemplateDay],
        monthlyItems: [HouseworkTemplateMonthlyItem] = []
    ) -> Self {
        let days: [DayOfWeek: [HouseworkTemplateItem]] = template.reduce(into: [:]) { partialResult, day in
            partialResult.updateValue(day.items, forKey: day.dayOfWeek)
        }
        return .init(days: days, monthlyItems: monthlyItems)
    }

    /// 指定された曜日に登録されているアイテム一覧を返す
    func items(in day: DayOfWeek) -> [HouseworkTemplateItem] {
        days[day] ?? []
    }

    /// あるアイテムが登録されている曜日を表示順で返す
    func registeredDays(for itemId: HouseworkTemplateItem.ItemId) -> [DayOfWeek] {
        DayOfWeek.displayOrdered.filter { day in
            days[day]?.contains(where: { $0.id == itemId }) ?? false
        }
    }

    /// あるアイテムの繰り返し方を返す。どこにも登録されていない場合は`nil`
    func recurrence(for itemId: HouseworkTemplateItem.ItemId) -> HouseworkRecurrence? {
        if let monthlyItem = monthlyItems.first(where: { $0.id == itemId }) {
            return .monthly(monthlyItem.rule)
        }
        let registeredDays = registeredDays(for: itemId)
        return registeredDays.isEmpty ? nil : .weekly(Set(registeredDays))
    }

    /// 初期状態との差分があるか
    func hasUnsavedChanges(comparedTo initial: HouseworkTemplateDraft) -> Bool {
        self != initial
    }

    /// 新規アイテムを指定された繰り返し方で追加する（毎週なら指定された曜日それぞれに追加する）
    mutating func addItem(_ item: HouseworkTemplateItem, recurrence: HouseworkRecurrence) {
        switch recurrence {
        case let .weekly(targetDays):
            for day in targetDays {
                days[day, default: []].append(item)
            }

        case let .monthly(rule):
            monthlyItems = Self.sortedForDisplay(monthlyItems + [.init(item: item, rule: rule)])
        }
    }

    /// 既存アイテムを全ての登録先（全曜日・毎月）から削除し、指定された繰り返し方で再登録する
    mutating func replaceItem(_ item: HouseworkTemplateItem, recurrence: HouseworkRecurrence) {
        removeItem(item.id, from: nil)
        addItem(item, recurrence: recurrence)
    }

    /// アイテムを削除する。`day` を指定するとその曜日のみ、`nil` の場合は全曜日と毎月の家事から削除する
    mutating func removeItem(_ itemId: HouseworkTemplateItem.ItemId, from day: DayOfWeek?) {
        if let day {
            days[day]?.removeAll { $0.id == itemId }
        } else {
            for day in DayOfWeek.allCases {
                days[day]?.removeAll { $0.id == itemId }
            }
            monthlyItems.removeAll { $0.id == itemId }
        }
    }

    /// アイテムの登録曜日に `destination` を追加する。
    /// 既に `destination` に同じアイテムが登録されている、もしくはアイテム自体が見つからない場合は何もしない。
    /// 追加した曜日の新エントリは `updatedAt` を `now` で作成する（既存曜日の `updatedAt` は変更しない）。
    mutating func addDay(
        to itemId: HouseworkTemplateItem.ItemId,
        destination: DayOfWeek,
        now: Date
    ) {
        if days[destination]?.contains(where: { $0.id == itemId }) == true {
            return
        }
        var sourceItem: HouseworkTemplateItem?
        for day in DayOfWeek.allCases {
            if let item = days[day]?.first(where: { $0.id == itemId }) {
                sourceItem = item
                break
            }
        }
        guard let sourceItem else { return }
        let added = HouseworkTemplateItem(
            id: sourceItem.id,
            title: sourceItem.title,
            point: sourceItem.point,
            updatedAt: now
        )
        days[destination, default: []].append(added)
    }

}

private extension HouseworkTemplateDraft {

    static func sortedForDisplay(_ monthlyItems: [HouseworkTemplateMonthlyItem]) -> [HouseworkTemplateMonthlyItem] {
        monthlyItems.sorted { lhs, rhs in
            if lhs.rule == rhs.rule {
                return lhs.id.id < rhs.id.id
            }
            return MonthlyRecurrenceRule.isOrderedBefore(lhs.rule, rhs.rule)
        }
    }

}
