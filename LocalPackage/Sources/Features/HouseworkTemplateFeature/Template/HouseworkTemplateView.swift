//
//  HouseworkTemplateView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/15.
//

import HometeDomain
import HometeUI
import SwiftUI

struct HouseworkTemplateView: View {

    @Environment(\.now) var now
    @Environment(\.dismiss) var dismiss

    @State var editingDays: [DayOfWeek: [HouseworkTemplateItem]] = [:]
    @State var presentingAddModal = false
    @State var presentingEditModal: HouseworkTemplateItem?
    @State var presentingCancelAlert = false
    @State var presentingDetailItem: HouseworkTemplateItem?
    @State var bannerDismissedInSession = false

    let hasTemplate: Bool
    let initialDays: [DayOfWeek: [HouseworkTemplateItem]]
    /// 編集中の他ユーザー名（自分以外、アクティブなもの）
    let activeOtherEditorNames: [String]

    var body: some View {
        ZStack {
            if hasTemplate {
                ZStack {
                    mainContent()
                    addItemButton()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.trailing, .space24)
                        .padding(.bottom, .space24)
                }
            } else {
                HouseworkTemplateEmptyView {
                    // TODO: テンプレート作成処理
                }
            }
        }
        .navigationTitle("家事テンプレート")
        .inlineNavigationBarTitleDisplayMode()
        .leadingToolbarItem {
            leadingNavigationItem()
        }
        .trailingToolbarItem {
            trailingNavigationItem()
                .tint(.red)
        }
        .sheet(isPresented: $presentingAddModal) {
            HouseworkTemplateItemEditModal(mode: .create) { input in
                tappedCreateItemButton(input: input)
            }
        }
        .sheet(item: $presentingEditModal) { item in
            HouseworkTemplateItemEditModal(
                mode: .edit(before: .init(
                    item: item,
                    selectedDays: Set(registeredDays(for: item))
                ))
            ) { input in
                tappedEditItemButton(input: input)
            }
        }
        .navigationDestination(item: $presentingDetailItem) { item in
            HouseworkTemplateItemDetailView(
                item: item,
                registeredDays: registeredDays(for: item),
                isEditing: false, // TODO: 後で消す
                onEdit: { input in
                    tappedEditItemButton(input: input)
                },
                onDelete: {
                    tappedDeleteItemButton(itemId: item.id)
                }
            )
        }
        .alert("変更を破棄します。よろしいですか？", isPresented: $presentingCancelAlert) {
            Button("破棄", role: .destructive) {
                tappedDiscardChangesAlertButton()
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

}

// MARK: - メインコンテンツ

private extension HouseworkTemplateView {

    func mainContent() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .space16) {
                HouseworkTemplateEditorsLabel(editorNames: activeOtherEditorNames)
                if !activeOtherEditorNames.isEmpty, !bannerDismissedInSession {
                    HouseworkTemplateConflictBanner {
                        bannerDismissedInSession = true
                    }
                }
                ForEach(DayOfWeek.displayOrdered) { day in
                    daySection(day)
                }
                Spacer(minLength: .space48)
            }
            .padding(.space16)
        }
    }

    func daySection(_ day: DayOfWeek) -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text(day.fullLabel)
                .font(with: .headLineS)
                .foregroundStyle(.onSubSurface)
            VStack(spacing: .space8) {
                if let items = editingDays[day],
                   !items.isEmpty {
                    ForEach(items, id: \.id) { item in
                        itemRow(item, in: day)
                    }
                } else {
                    emptyDayRow()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.space8)
            .background {
                RoundedRectangle(radius: .radius8)
                    .fill(.subSurface)
            }
            .dropDestination(for: String.self) { ids, _ in
                guard let droppedId = ids.first else { return false }
                onDropItem(itemId: .init(id: droppedId), to: day)
                return true
            }
        }
    }

    func emptyDayRow() -> some View {
        Text("家事なし")
            .font(with: .caption)
            .foregroundStyle(.onSubSurface)
            .padding(.vertical, .space8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func itemRow(_ item: HouseworkTemplateItem, in day: DayOfWeek) -> some View {
        let row = HouseworkTemplateItemRow(item: item)
            .contentShape(Rectangle())
            .onTapGesture {
                presentingDetailItem = item
            }
        row
            .draggable(item.id.id)
            .contextMenu {
                Button("編集") {
                    presentingEditModal = item
                }
                Button("削除", role: .destructive) {
                    tappedDeleteItemButton(itemId: item.id, from: day)
                }
            }
    }

    func addItemButton() -> some View {
        Button {
            presentingAddModal = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24))
        }
        .floatingButtonStyle()
    }

}

// MARK: - ナビゲーションバー

private extension HouseworkTemplateView {

    func leadingNavigationItem() -> some View {
        Button {
            tappedCancelButton()
        } label: {
            Image(systemName: "xmark")
        }
        .foregroundStyle(.onSurface)
    }

    func trailingNavigationItem() -> some View {
        Group {
            if #available(iOS 26.0, *) {
                Button("保存", systemImage: "checkmark", role: .confirm) {
                    tappedSaveButton()
                }
            } else {
                Button {
                    tappedSaveButton()
                } label: {
                    Image(systemName: "checkmark")
                }
            }
        }
        .tint(.primary1)
        .foregroundStyle(.onPrimary1)
        .disabled(!hasUnsavedChanges)
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkTemplateView {

    // TODO: ドメインロジックに切り出す
    var hasUnsavedChanges: Bool {
        editingDays != initialDays
    }

    // TODO: ドメインロジックに切り出す
    func registeredDays(for item: HouseworkTemplateItem) -> [DayOfWeek] {
        DayOfWeek.displayOrdered.filter { day in
            editingDays[day]?.contains(where: { $0.id == item.id }) ?? false
        }
    }

    func tappedCreateItemButton(input: TemplateItemEditInput) {
        // TODO: ドメインロジックに切り出す
        let item = input.createTemplate(now: now)
        for day in input.days {
            editingDays[day, default: []].append(item)
        }
    }

    func tappedEditItemButton(input: TemplateItemEditInput) {
        // TODO: ドメインロジックに切り出す
        for day in DayOfWeek.allCases {
            editingDays[day]?.removeAll { $0.id == input.itemId }
        }
        let newItem = input.createTemplate(now: now)
        for day in input.days {
            editingDays[day, default: []].append(newItem)
        }
    }

    func tappedDeleteItemButton(itemId: HouseworkTemplateItem.ItemId, from day: DayOfWeek? = nil) {
        if let day {
            editingDays[day]?.removeAll { $0.id == itemId }
        } else {
            for day in DayOfWeek.allCases {
                editingDays[day]?.removeAll { $0.id == itemId }
            }
        }
    }

    func onDropItem(itemId: HouseworkTemplateItem.ItemId, to destination: DayOfWeek) {
        // TODO: ドメインロジックに切り出す
        var movingItem: HouseworkTemplateItem?
        for day in DayOfWeek.allCases {
            if let index = editingDays[day]?.firstIndex(where: { $0.id == itemId }) {
                movingItem = editingDays[day]?.remove(at: index)
                if day == destination {
                    // 同じ曜日へのドロップ：何もせず戻す
                    if let movingItem {
                        editingDays[day, default: []].insert(movingItem, at: index)
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
            updatedAt: Date()
        )
        editingDays[destination, default: []].append(updated)
    }

    func tappedCancelButton() {
        dismiss()
    }

    func tappedDiscardChangesAlertButton() {
        // コンフリクトしたら、最新のテンプレート内容を再ロードして、編集内容は破棄する
        editingDays = initialDays
    }

    func tappedSaveButton() {
        // TODO: 後続で Store 経由の保存処理に置き換える。
    }

}

#if DEBUG
    #Preview("HouseworkTemplateView_閲覧モード") {
        let templateData: [DayOfWeek: [HouseworkTemplateItem]] = [
            .monday: [
                .init(
                    id: .init(id: "1"),
                    title: "hoge",
                    point: 10,
                    updatedAt: .now
                ),
            ],
            .tuesday: [
                .init(
                    id: .init(id: "1"),
                    title: "hoge",
                    point: 10,
                    updatedAt: .now
                ),
                .init(
                    id: .init(id: "2"),
                    title: "hoge2",
                    point: 15,
                    updatedAt: .now
                ),
            ],
            .wednesday: [
                .init(
                    id: .init(id: "1"),
                    title: "hoge",
                    point: 10,
                    updatedAt: .now
                ),
            ],
            .thursday: [
                .init(
                    id: .init(id: "1"),
                    title: "hoge",
                    point: 10,
                    updatedAt: .now
                ),
                .init(
                    id: .init(id: "3"),
                    title: "hoge3",
                    point: 90,
                    updatedAt: .now
                ),
            ],
            .friday: [
                .init(
                    id: .init(id: "1"),
                    title: "hoge",
                    point: 10,
                    updatedAt: .now
                ),
            ],
            .saturday: [
                .init(
                    id: .init(id: "1"),
                    title: "hoge",
                    point: 10,
                    updatedAt: .now
                ),
            ],
            .sunday: [
                .init(
                    id: .init(id: "1"),
                    title: "hoge",
                    point: 10,
                    updatedAt: .now
                ),
            ],
        ]
        NavigationStack {
            HouseworkTemplateView(
                editingDays: templateData,
                hasTemplate: true,
                initialDays: templateData,
                activeOtherEditorNames: []
            )
        }
        .apply(theme: .init())
    }

    #Preview("HouseworkTemplateView_アクティブユーザー有り") {
        let templateData: [DayOfWeek: [HouseworkTemplateItem]] = [
            .monday: [
                .init(
                    id: .init(id: "1"),
                    title: "hoge",
                    point: 10,
                    updatedAt: .now
                ),
            ],
        ]
        NavigationStack {
            HouseworkTemplateView(
                editingDays: [:],
                hasTemplate: true,
                initialDays: templateData,
                activeOtherEditorNames: ["Aさん", "Bさん"]
            )
        }
        .tint(.red)
        .apply(theme: .init())
    }
#endif
