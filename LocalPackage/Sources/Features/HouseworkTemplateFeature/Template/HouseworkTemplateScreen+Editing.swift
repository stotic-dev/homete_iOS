//
//  HouseworkTemplateScreen+Editing.swift
//  LocalPackage
//

import HometeDomain
import SwiftUI

// MARK: - 編集のプレゼンテーションロジック

extension HouseworkTemplateScreen {

    /// メモの上限の判定に使う、操作している本人のプラン
    var memoLimitPolicy: HouseworkMemoLimitPolicy {
        .init(isPremium: subscriptionStore.isPremium)
    }

    /// 編集・詳細画面に渡すアイテムの繰り返し方
    /// - Note: 表示中のアイテムは必ずどこかに登録されているため、見つからないのは表示直後に削除された場合だけ
    func recurrence(for item: HouseworkTemplateItem) -> HouseworkRecurrence {
        editingDraft.recurrence(for: item.id) ?? .weekly([])
    }

    func tappedCreateItemButton(input: TemplateItemEditInput) {
        guard let recurrence = input.recurrence.recurrence else { return }
        let item = input.createTemplate(now: now)
        editingDraft.addItem(item, recurrence: recurrence)
    }

    func tappedEditItemButton(input: TemplateItemEditInput) {
        guard let recurrence = input.recurrence.recurrence else { return }
        let newItem = input.createTemplate(now: now)
        editingDraft.replaceItem(newItem, recurrence: recurrence)
    }

    func tappedDeleteItemButton(itemId: HouseworkTemplateItem.ItemId, from day: DayOfWeek? = nil) {
        editingDraft.removeItem(itemId, from: day)
    }

    func onDropItem(itemId: HouseworkTemplateItem.ItemId, to destination: DayOfWeek) {
        editingDraft.addDay(to: itemId, destination: destination, now: now)
    }

    func tappedCancelButton() {
        if initialDraft?.hasUnsavedChanges(comparedTo: editingDraft) == true {
            // 保存していない変更内容がある場合に、閉じようとした時はアラートを表示する
            presentingDismissAlert = true
        } else {
            dismiss()
        }
    }

    func tappedDismissAlertButton() {
        dismiss()
    }

    func tappedDiscardChangesAlertButton() {
        guard let initialDraft else { return }
        // コンフリクトしたら、最新のテンプレート内容を再ロードして、編集内容は破棄する
        withAnimation {
            editingDraft = initialDraft
        }
        // draftを最新内容に追従させたタイミングで初めて楽観ロックのバージョンを進める
        editorContext = editorContext.applyEditors(templateEditStore.currentVersion)
    }

    func tappedResetAlertButton() {
        guard let initialDraft else { return }
        withAnimation {
            editingDraft = initialDraft
        }
    }

    func tappedSaveButton(templateId: String) async {
        guard let cohabitantId = account.cohabitantId else { return }
        do {
            try await houseworkTemplateListStore.saveTemplate(
                days: editingDraft.saveDays,
                monthlyItems: editingDraft.monthlyItems,
                templateId: templateId,
                cohabitantId: cohabitantId,
                currentVersion: editorContext.currentTemplateVersion,
                memoLimitPolicy: memoLimitPolicy
            )
            // 保存が完了したら比較元のテンプレート情報を更新後の値に変更する(コンフリクト検知に引っかからないため)
            editorContext = editorContext.applyEditors(editorContext.currentTemplateVersion + 1)
            initialDraft = editingDraft
        } catch HouseworkTemplateError.versionConflict {
            // 保存タイミングと metaVersion 監視のレースで versionConflict を先に検知した場合の保険
            presentingConflictDraftAlert = true
        } catch {
            editErrorContent = .init(error: error)
        }
    }

    func tappedCreateTemplateButton() async {
        guard let cohabitantId = account.cohabitantId else { return }

        do {
            try await houseworkTemplateListStore.createTemplate(
                templateId: UUID().uuidString,
                name: "default",
                cohabitantId: cohabitantId
            )
        } catch {
            editErrorContent = .init(error: error)
        }
    }

    func onChangeInitialDraft() {
        // 現在の編集内容と差分がある場合はコンフリクトとして処理する
        guard let initialDraft,
              initialDraft.hasUnsavedChanges(comparedTo: editingDraft) else { return }
        presentingConflictDraftAlert = true
    }

}
