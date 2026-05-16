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

    @State var isPresentingEditModal = false

    let item: HouseworkTemplateItem
    let registeredDays: [DayOfWeek]
    let onEdit: (TemplateItemEditInput) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .space24) {
            row(label: "ポイント") {
                PointLabel(point: item.point)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            selectedDayOfWeeks()
            Spacer()
        }
        .padding(.horizontal, .space16)
        .padding(.vertical, .space24)
        .navigationTitle(item.title)
        .inlineNavigationBarTitleDisplayMode()
        .trailingToolbarItem {
            editingButton()
        }
        .sheet(isPresented: $isPresentingEditModal) {
            HouseworkTemplateItemEditModal(
                mode: .edit(before: .init(
                    item: item,
                    selectedDays: .init(registeredDays)
                )),
                onConfirm: { input in
                    onEdit(input)
                }
            )
        }
    }

}

private extension HouseworkTemplateItemDetailView {

    func row(label: String, @ViewBuilder valueContent: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text(label)
                .font(with: .headLineS)
                .foregroundStyle(.onSubSurface)
            valueContent()
        }
    }

    func selectedDayOfWeeks() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("登録曜日")
                .font(with: .headLineS)
                .foregroundStyle(.onSubSurface)
            HStack(spacing: .space8) {
                ForEach(registeredDays) { day in
                    WeekdayLabel(
                        weekday: day,
                        isSelected: true
                    )
                    .frame(width: 40)
                }
                Spacer()
            }
        }
    }

    func editingButton() -> some View {
        HStack(spacing: .space8) {
            Button {
                isPresentingEditModal = true
            } label: {
                Image(systemName: "pencil")
                    .foregroundStyle(.onSurface)
            }
            NavigationBarButton(label: .delete) {
                onDelete()
                dismiss()
            }
        }
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
            registeredDays: [.monday, .wednesday],
            onEdit: { _ in },
            onDelete: {}
        )
    }
}
