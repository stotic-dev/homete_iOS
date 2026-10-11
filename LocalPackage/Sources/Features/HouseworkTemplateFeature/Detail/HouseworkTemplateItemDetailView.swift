//
//  HouseworkTemplateItemDetailView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import HometeDomain
import HometeUI
import SwiftUI

struct HouseworkTemplateItemDetailView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.now) var now

    @State var isPresentingEditModal = false
    @State var item: HouseworkTemplateItem

    let recurrence: HouseworkRecurrence
    let onEdit: (TemplateItemEditInput) -> Void
    let onDelete: () -> Void

    var body: some View {
        // メモが長くても読み切れるようにスクロールさせる
        ScrollView {
            VStack(alignment: .leading, spacing: .space24) {
                row(label: .localized("ポイント")) {
                    PointLabel(point: item.point)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                recurrenceContent()
                if let memo = item.memo, !memo.isEmpty {
                    row(label: .localized("メモ")) {
                        // テンプレートのメモのチェックは、作られた家事の側で付ける
                        HouseworkMemoContent(memo: memo, isEditable: false, onToggle: { _ in })
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .space16)
            .padding(.vertical, .space24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle(item.title)
        .inlineNavigationBarTitleDisplayMode()
        .trailingToolbarItem {
            editingButton()
        }
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

// MARK: - UI定義

private extension HouseworkTemplateItemDetailView {

    func row(label: LocalizedStringResource, @ViewBuilder valueContent: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text(label)
                .font(with: .headLineS)
                .foregroundStyle(.textPrimary)
            valueContent()
        }
    }

    @ViewBuilder
    func recurrenceContent() -> some View {
        switch recurrence {
        case let .weekly(days) where days.count == DayOfWeek.allCases.count:
            row(label: .localized("くり返し")) {
                Text("毎日", bundle: #bundle)
                    .font(with: .body)
                    .foregroundStyle(.textPrimary)
            }

        case let .weekly(days):
            row(label: .localized("くり返す曜日")) {
                HStack(spacing: .space8) {
                    ForEach(DayOfWeek.displayOrdered.filter { days.contains($0) }) { day in
                        WeekdayLabel(
                            weekday: day,
                            isSelected: true
                        )
                        .frame(width: 40)
                    }
                    Spacer()
                }
            }

        case let .monthly(rule):
            row(label: .localized("くり返し")) {
                Text(rule.label)
                    .font(with: .body)
                    .foregroundStyle(.textPrimary)
            }
        }
    }

    func editingButton() -> some View {
        HStack(spacing: .space8) {
            Button {
                tappedEditButton()
            } label: {
                Image(systemName: "pencil")
                    .foregroundStyle(.textPrimary)
            }
            NavigationBarButton(label: .delete) {
                tappedDeleteButton()
            }
        }
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkTemplateItemDetailView {

    func tappedDeleteButton() {
        onDelete()
        dismiss()
    }

    func tappedEditButton() {
        isPresentingEditModal = true
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

#Preview("HouseworkTemplateItemDetailView_閲覧モード") {
    NavigationStack {
        HouseworkTemplateItemDetailView(
            item: .init(
                id: .init(id: "1"),
                title: "洗濯",
                point: 10,
                updatedAt: .distantPast
            ),
            recurrence: .weekly([.monday, .wednesday]),
            onEdit: { _ in },
            onDelete: {}
        )
    }
}

#Preview("HouseworkTemplateItemDetailView_メモあり") {
    NavigationStack {
        HouseworkTemplateItemDetailView(
            item: .init(
                id: .init(id: "1"),
                title: "買い出し",
                point: 10,
                updatedAt: .distantPast,
                memo: .init(
                    text: "駅前のスーパーで",
                    checklist: [
                        .init(id: "1", title: "牛乳", isChecked: false),
                        .init(id: "2", title: "卵", isChecked: false),
                    ]
                )
            ),
            recurrence: .weekly([.saturday]),
            onEdit: { _ in },
            onDelete: {}
        )
    }
}

#Preview("HouseworkTemplateItemDetailView_毎月") {
    NavigationStack {
        HouseworkTemplateItemDetailView(
            item: .init(
                id: .init(id: "1"),
                title: "家賃の振込",
                point: 5,
                updatedAt: .distantPast
            ),
            recurrence: .monthly(.dayOfMonth(25)),
            onEdit: { _ in },
            onDelete: {}
        )
    }
}

#Preview("HouseworkTemplateItemDetailView_毎日") {
    NavigationStack {
        HouseworkTemplateItemDetailView(
            item: .init(
                id: .init(id: "1"),
                title: "食器洗い",
                point: 5,
                updatedAt: .distantPast
            ),
            recurrence: .weekly(Set(DayOfWeek.allCases)),
            onEdit: { _ in },
            onDelete: {}
        )
    }
}
