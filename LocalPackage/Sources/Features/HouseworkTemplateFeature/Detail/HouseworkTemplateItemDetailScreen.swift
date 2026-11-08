//
//  HouseworkTemplateItemDetailScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import HouseworkTemplateFeatureUI
import SwiftUI

/// テンプレートの家事の詳細画面（テンプレートからpushで開く）
struct HouseworkTemplateItemDetailScreen: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.now) var now

    @State var isPresentingEditModal = false
    @State var item: HouseworkTemplateItem

    let recurrence: HouseworkRecurrence
    let onEdit: (TemplateItemEditInput) -> Void
    let onDelete: () -> Void

    var body: some View {
        HouseworkTemplateItemDetailView(
            item: item,
            recurrence: recurrence,
            onTapEdit: { isPresentingEditModal = true },
            onTapDelete: { tappedDeleteButton() }
        )
        .sheet(isPresented: $isPresentingEditModal) {
            HouseworkTemplateItemEditModalScreen(
                mode: .edit(before: .init(item: item, recurrence: recurrence)),
                onConfirm: { input in
                    onEdited(input)
                }
            )
        }
        .trackScreenView(.houseworkTemplateDetail)
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkTemplateItemDetailScreen {

    func tappedDeleteButton() {
        onDelete()
        dismiss()
    }

    func onEdited(_ editedInput: TemplateItemEditInput) {
        item = .init(
            id: editedInput.itemId,
            title: editedInput.title,
            point: editedInput.point ?? 0,
            updatedAt: now
        )
        onEdit(editedInput)
    }

}
