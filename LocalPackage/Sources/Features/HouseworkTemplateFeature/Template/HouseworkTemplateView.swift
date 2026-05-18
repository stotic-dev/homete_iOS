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

    @Environment(HouseworkTemplateListStore.self) var templateListStore
    @Environment(\.now) var now
    @Environment(\.dismiss) var dismiss
    @Environment(\.loginContext.cohabitantId) var cohabitantId

    @State var draft: HouseworkTemplateDraft = .init()
    @State var presentingAddModal = false
    @State var presentingEditModal: HouseworkTemplateItem?
    @State var presentingCancelAlert = false
    @State var presentingDetailItem: HouseworkTemplateItem?
    @State var bannerDismissedInSession = false

    @Binding var initialDraft: HouseworkTemplateDraft
    let editorContext: TemplateEditorContext
    let templateId: String?

    var body: some View {
        ZStack {
            if let templateId {
                ZStack {
                    mainContent()
                    addItemButton()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.trailing, .space24)
                        .padding(.bottom, .space8)
                }
                .trailingToolbarItem {
                    trailingNavigationItem(templateId: templateId)
                }
            } else {
                HouseworkTemplateEmptyView {
                    Task {
                        await tappedCreateTemplateButton()
                    }
                }
            }
        }
        .navigationTitle("家事テンプレート")
        .inlineNavigationBarTitleDisplayMode()
        .leadingToolbarItem {
            leadingNavigationItem()
        }
        .safeAreaInset(edge: .top) {
            HouseworkTemplateEditorsLabel(
                bannerDismissedInSession: $bannerDismissedInSession,
                activeEditors: editorContext.currentActiveEditors
            )
            .padding(.horizontal, .space16)
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
                    selectedDays: Set(draft.registeredDays(for: item.id))
                ))
            ) { input in
                tappedEditItemButton(input: input)
            }
        }
        .navigationDestination(item: $presentingDetailItem) { item in
            HouseworkTemplateItemDetailView(
                item: item,
                registeredDays: draft.registeredDays(for: item.id),
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
                ForEach(DayOfWeek.displayOrdered) { day in
                    daySection(day)
                }
            }
            .padding(.horizontal, .space16)
            .padding(.top, .space32)
            .padding(.bottom, .space64)
        }
    }

    func daySection(_ day: DayOfWeek) -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text(day.fullLabel)
                .font(with: .headLineS)
                .foregroundStyle(.onSubSurface)
            VStack(spacing: .space8) {
                let items = draft.items(in: day)
                if !items.isEmpty {
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

    func trailingNavigationItem(templateId: String) -> some View {
        NavigationBarPrimaryActionButton(systemImage: "checkmark") {
            Task {
                await tappedSaveButton(templateId: templateId)
            }
        }
        .disabled(!draft.hasUnsavedChanges(comparedTo: initialDraft))
    }

}

// MARK: - プレゼンテーションロジック

private extension HouseworkTemplateView {

    func tappedCreateItemButton(input: TemplateItemEditInput) {
        let item = input.createTemplate(now: now)
        draft.addItem(item, to: input.days)
    }

    func tappedEditItemButton(input: TemplateItemEditInput) {
        let newItem = input.createTemplate(now: now)
        draft.replaceItem(newItem, in: input.days)
    }

    func tappedDeleteItemButton(itemId: HouseworkTemplateItem.ItemId, from day: DayOfWeek? = nil) {
        draft.removeItem(itemId, from: day)
    }

    func onDropItem(itemId: HouseworkTemplateItem.ItemId, to destination: DayOfWeek) {
        draft.moveItem(itemId, to: destination, now: now)
    }

    func tappedCancelButton() {
        dismiss()
    }

    func tappedDiscardChangesAlertButton() {
        // コンフリクトしたら、最新のテンプレート内容を再ロードして、編集内容は破棄する
        draft = initialDraft
    }

    func tappedSaveButton(templateId: String) async {
        guard let cohabitantId else { return }
        do {
            try await templateListStore.saveDays(
                draft.saveDays,
                templateId: templateId,
                cohabitantId: cohabitantId,
                currentVersion: editorContext.currentTemplateVersion
            )
            // 保存が完了したら比較元のテンプレート情報を更新後の値に変更する(コンフリクト検知に引っかからないため)
            initialDraft = draft
        } catch {
            // TODO: エラーハンドリング
        }
    }

    func tappedCreateTemplateButton() async {
        guard let cohabitantId else { return }

        do {
            try await templateListStore.createTemplate(
                templateId: UUID().uuidString,
                name: "default",
                cohabitantId: cohabitantId
            )
        } catch {
            // TODO: エラーハンドリング
        }
    }

}

// MARK: - Preview

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
            draft: .init(days: templateData),
            initialDraft: .constant(.init(days: templateData)),
            editorContext: .init(currentActiveEditors: [], currentTemplateVersion: .zero),
            templateId: ""
        )
    }
    .environment(
        \.houseworkTemplateContext,
        .init(
            metadata: .init(templateId: "", name: ""),
            houseworkTemplate: [
                .init(dayOfWeek: 1, items: []),
            ]
        )
    )
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
            draft: .init(),
            initialDraft: .constant(.init(days: templateData)),
            editorContext: .init(
                currentActiveEditors: [
                    .init(id: "1", userName: "Aさん"),
                    .init(id: "2", userName: "Bさん"),
                ],
                currentTemplateVersion: .zero
            ),
            templateId: ""
        )
    }
    .environment(
        \.houseworkTemplateContext,
        .init(
            metadata: .init(templateId: "", name: ""),
            houseworkTemplate: [
                .init(dayOfWeek: 1, items: []),
            ]
        )
    )
    .apply(theme: .init())
}
#endif
