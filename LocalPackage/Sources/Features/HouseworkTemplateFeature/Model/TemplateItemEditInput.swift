//
//  TemplateItemEditInput.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/16.
//

import Foundation
import HometeDomain

/// モーダルの入出力データ。
struct TemplateItemEditInput: Equatable {

    var itemId: HouseworkTemplateItem.ItemId
    var title: String
    /// `nil`はポイント未選択を表す。
    var point: Int?
    var days: Set<DayOfWeek>

    static func initial(_ id: UUID) -> Self {
        TemplateItemEditInput(
            itemId: .init(uuid: id),
            title: "",
            point: nil,
            days: []
        )
    }

    var isEmptyTitle: Bool {
        title.isEmpty
    }

    func canConfirm(_ mode: EditMode) -> Bool {
        // 全ての項目が入力済みであること
        let isAllInputed = !title.trimmingCharacters(in: .whitespaces).isEmpty
            && !days.isEmpty
            && point != nil

        if case let .edit(before) = mode {
            // 編集モードの場合は、既存の内容から変更が加わっていることも条件に含める
            return before != self && isAllInputed
        } else {
            return isAllInputed
        }
    }

    func createTemplate(now: Date) -> HouseworkTemplateItem {
        .init(
            id: itemId,
            title: title,
            point: point ?? 0,
            updatedAt: now
        )
    }

}

extension TemplateItemEditInput {

    init(item: HouseworkTemplateItem, selectedDays: Set<DayOfWeek>) {
        self.init(
            itemId: item.id,
            title: item.title,
            point: item.point,
            days: selectedDays
        )
    }

}
