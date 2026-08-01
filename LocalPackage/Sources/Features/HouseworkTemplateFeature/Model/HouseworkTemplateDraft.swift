//
//  HouseworkTemplateDraft.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/16.
//

import Foundation
import HometeDomain

/// 家事テンプレート編集中の状態を表すモデル。曜日別のアイテム集合を保持し、編集操作を提供する。
struct HouseworkTemplateDraft: Equatable {

    private(set) var days: [DayOfWeek: [HouseworkTemplateItem]]

    /// 保存するテンプレートのモデルを返す
    var saveDays: [HouseworkTemplateDay] {
        days.map { .init(dayOfWeek: $0.key, items: $0.value) }
    }

    init(days: [DayOfWeek: [HouseworkTemplateItem]] = [:]) {
        self.days = days
    }

    /// 入力されたテンプレートから編集用のモデルを生成
    static func make(_ template: [HouseworkTemplateDay]) -> Self {
        let days: [DayOfWeek: [HouseworkTemplateItem]] = template.reduce(into: [:]) { partialResult, day in
            partialResult.updateValue(day.items, forKey: day.dayOfWeek)
        }
        return .init(days: days)
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

    /// 初期状態との差分があるか
    func hasUnsavedChanges(comparedTo initial: HouseworkTemplateDraft) -> Bool {
        self != initial
    }

    /// 新規アイテムを指定された曜日それぞれに追加する
    mutating func addItem(_ item: HouseworkTemplateItem, to targetDays: Set<DayOfWeek>) {
        for day in targetDays {
            days[day, default: []].append(item)
        }
    }

    /// 既存アイテムを全曜日から削除し、指定された曜日に再登録する
    mutating func replaceItem(_ item: HouseworkTemplateItem, in targetDays: Set<DayOfWeek>) {
        removeItem(item.id, from: nil)
        addItem(item, to: targetDays)
    }

    /// アイテムを削除する。`day` を指定するとその曜日のみ、`nil` の場合は全曜日から削除する
    mutating func removeItem(_ itemId: HouseworkTemplateItem.ItemId, from day: DayOfWeek?) {
        if let day {
            days[day]?.removeAll { $0.id == itemId }
        } else {
            for day in DayOfWeek.allCases {
                days[day]?.removeAll { $0.id == itemId }
            }
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
