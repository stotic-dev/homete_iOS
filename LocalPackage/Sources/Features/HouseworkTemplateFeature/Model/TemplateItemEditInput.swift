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
    var recurrence: HouseworkRecurrenceInput

    static func initial(_ id: UUID) -> Self {
        TemplateItemEditInput(
            itemId: .init(uuid: id),
            title: "",
            point: nil,
            recurrence: .init(kind: .weekly)
        )
    }

    var isEmptyTitle: Bool {
        title.isEmpty
    }

    func canConfirm(_ mode: EditMode) -> Bool {
        // 全ての項目が入力済みであること
        let isAllInputed = !title.trimmingCharacters(in: .whitespaces).isEmpty
            && recurrence.recurrence != nil
            && point != nil

        if case let .edit(before) = mode {
            // 編集モードの場合は、既存の内容から変更が加わっていることも条件に含める
            return hasChanges(from: before) && isAllInputed
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

private extension TemplateItemEditInput {

    /// 保存される内容が既存の内容から変わっているか
    /// - Note: 繰り返し方は選択中の種類の値だけで比べる（種類を切り替えて戻しただけなら変更なしとみなす）
    func hasChanges(from before: Self) -> Bool {
        title != before.title
            || point != before.point
            || recurrence.recurrence != before.recurrence.recurrence
    }

}

extension TemplateItemEditInput {

    init(item: HouseworkTemplateItem, recurrence: HouseworkRecurrence) {
        self.init(
            itemId: item.id,
            title: item.title,
            point: item.point,
            recurrence: .init(recurrence: recurrence)
        )
    }

}
