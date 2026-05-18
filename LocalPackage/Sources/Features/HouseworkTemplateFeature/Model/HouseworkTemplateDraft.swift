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

    init(days: [DayOfWeek: [HouseworkTemplateItem]] = [:]) {
        self.days = days
    }

    /// 入力されたテンプレートから編集用のモデルを生成
    static func make(_ template: [HouseworkTemplateDay]) -> Self {
        let days: [DayOfWeek: [HouseworkTemplateItem]] = template.reduce([:]) { partialResult, day in
            guard let dayOfWeek = DayOfWeek(rawValue: day.dayOfWeek) else { return partialResult }
            var partialResult = partialResult
            partialResult.updateValue(day.items, forKey: dayOfWeek)
            return partialResult
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

    /// アイテムを指定された曜日に移動する。同じ曜日へのドロップは何もしない。
    /// 異なる曜日へ移動した場合は `updatedAt` を `now` に更新する。
    mutating func moveItem(
        _ itemId: HouseworkTemplateItem.ItemId,
        to destination: DayOfWeek,
        now: Date
    ) {
        var movingItem: HouseworkTemplateItem?
        for day in DayOfWeek.allCases {
            if let index = days[day]?.firstIndex(where: { $0.id == itemId }) {
                movingItem = days[day]?.remove(at: index)
                if day == destination {
                    if let movingItem {
                        days[day, default: []].insert(movingItem, at: index)
                    }
                    return
                }
            }
        }
        guard let movingItem else { return }
        let updated = HouseworkTemplateItem(
            id: movingItem.id,
            title: movingItem.title,
            point: movingItem.point,
            updatedAt: now
        )
        days[destination, default: []].append(updated)
    }

}
