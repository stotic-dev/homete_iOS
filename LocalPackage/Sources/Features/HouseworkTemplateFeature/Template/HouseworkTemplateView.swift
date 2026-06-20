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

    @State var presentingAddModal = false
    @State var presentingEditModal: HouseworkTemplateItem?
    @State var presentingConflictDraftAlert = false
    @State var presentingDetailItem: HouseworkTemplateItem?
    @State var bannerDismissedInSession = false
    @State var presentingDismissAlert = false
    @State var presentingResetAlert = false

    @CommonError var commonErrorContent

    @AppStorage(key: .collapsedHouseworkTemplateDays) var collapsedDays = CollapsedHouseworkTemplateDays()

    @Binding var initialDraft: HouseworkTemplateDraft?
    @Binding var draft: HouseworkTemplateDraft
    @Binding var editorContext: TemplateEditorContext

    var body: some View {
        ZStack {
            if let templateId = templateListStore.selectedTemplateId,
               let initialDraft {
                ZStack {
                    mainContent()
                    addItemButton()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.trailing, .space24)
                        .padding(.bottom, .space8)
                }
                #if os(iOS)
                .toolbar {
                    trailingNavigationItem(
                        templateId: templateId,
                        initialDraft: initialDraft,
                        isEditing: initialDraft.hasUnsavedChanges(comparedTo: draft)
                    )
                }
                #endif
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
            HouseworkTemplateItemEditModalScreen(mode: .create) { input in
                tappedCreateItemButton(input: input)
            }
        }
        .sheet(item: $presentingEditModal) { item in
            HouseworkTemplateItemEditModalScreen(
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
        .onChange(of: initialDraft) {
            onChangeInitialDraft()
        }
        .alert("他メンバーのテンプレート更新が、あなたの変更と競合したので変更を破棄する必要があります。よろしいですか？", isPresented: $presentingConflictDraftAlert) {
            Button("破棄", role: .destructive) {
                tappedDiscardChangesAlertButton()
            }
            Button("キャンセル", role: .cancel) {}
        }
        .alert("変更内容はまだ確定していません", isPresented: $presentingDismissAlert) {
            Button("閉じる", role: .destructive) {
                tappedDismissAlertButton()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("このまま閉じられると変更中の内容が破棄されます。\n変更を確定する場合は保存してから閉じてください。")
        }
        .alert("編集前の状態に戻しますか？", isPresented: $presentingResetAlert) {
            Button("戻す", role: .destructive) {
                tappedResetAlertButton()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("現在の編集内容は破棄されます。")
        }
        .animation(.default, value: collapsedDays)
        .commonError(content: $commonErrorContent)
    }

}

// MARK: - メインコンテンツ

private extension HouseworkTemplateView {

    func mainContent() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .space16) {
                ForEach(DayOfWeek.displayOrdered) { day in
                    daySection(
                        day,
                        isCollapsed: collapsedDays.isCollapsed(day),
                        items: draft.items(in: day)
                    )
                }
            }
            .padding(.horizontal, .space16)
            .padding(.top, .space32)
            .padding(.bottom, .space64)
        }
    }

    func daySection(_ day: DayOfWeek, isCollapsed: Bool, items: [HouseworkTemplateItem]) -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            dayHeader(day, itemCount: items.count, isCollapsed: isCollapsed)
            if !isCollapsed {
                VStack(spacing: .space8) {
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
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .clipped()
//        .animation(.default, value: isCollapsed)
    }

    func dayHeader(_ day: DayOfWeek, itemCount: Int, isCollapsed: Bool) -> some View {
        Button {
            withAnimation {
                tappedDayHeaderButton(day)
            }
        } label: {
            HStack(spacing: .space8) {
                Image(systemName: "chevron.right")
                    .font(with: .caption)
                    .foregroundStyle(.onSubSurface)
                    .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                Text(day.fullLabel)
                    .font(with: .headLineS)
                    .foregroundStyle(.onSubSurface)
                if isCollapsed,
                   itemCount > 0 {
                    Text("(\(itemCount))")
                        .font(with: .caption)
                        .foregroundStyle(.onSubSurface)
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .dropDestination(for: String.self) { ids, _ in
            guard let droppedId = ids.first else { return false }
            onDropItem(itemId: .init(id: droppedId), to: day)
            if isCollapsed {
                withAnimation {
                    collapsedDays.toggle(day)
                }
            }
            return true
        }
    }

    func emptyDayRow() -> some View {
        Text("家事なし")
            .font(with: .caption)
            .foregroundStyle(.onSubSurface)
            .padding(.vertical, .space8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    func itemRow(_ item: HouseworkTemplateItem, in day: DayOfWeek) -> some View {
        HouseworkTemplateItemRow(item: item)
            .contentShape(Rectangle())
            .onTapGesture {
                presentingDetailItem = item
            }
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

    #if os(iOS)
    @ToolbarContentBuilder
    func trailingNavigationItem(
        templateId: String,
        initialDraft: HouseworkTemplateDraft,
        isEditing: Bool
    ) -> some ToolbarContent {
        if draft.hasUnsavedChanges(comparedTo: initialDraft) {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    presentingResetAlert = true
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .foregroundStyle(.onSurface)
            }
        }
        if #available(iOS 26.0, *) {
            ToolbarSpacer()
        }
        ToolbarItem(placement: .topBarTrailing) {
            NavigationBarPrimaryActionButton(systemImage: "checkmark") {
                Task {
                    await tappedSaveButton(templateId: templateId)
                }
            }
            .disabled(!isEditing)
        }
    }
    #endif

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
        draft.addDay(to: itemId, destination: destination, now: now)
    }

    func tappedCancelButton() {
        if initialDraft?.hasUnsavedChanges(comparedTo: draft) == true {
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
            draft = initialDraft
        }
    }

    func tappedResetAlertButton() {
        guard let initialDraft else { return }
        withAnimation {
            draft = initialDraft
        }
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
            editorContext = editorContext.applyEditors(editorContext.currentTemplateVersion + 1)
            initialDraft = draft
        } catch HouseworkTemplateError.versionConflict {
            // 保存タイミングと metaVersion 監視のレースで versionConflict を先に検知した場合の保険
            presentingConflictDraftAlert = true
        } catch {
            commonErrorContent = .init(error: error)
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
            commonErrorContent = .init(error: error)
        }
    }

    func onChangeInitialDraft() {
        // 現在の編集内容と差分がある場合はコンフリクトとして処理する
        guard let initialDraft,
              initialDraft.hasUnsavedChanges(comparedTo: draft) else { return }
        presentingConflictDraftAlert = true
    }

    func tappedDayHeaderButton(_ day: DayOfWeek) {
        collapsedDays.toggle(day)
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
            initialDraft: .constant(.init(days: templateData)),
            draft: .constant(.init(days: templateData)),
            editorContext: .constant(.init(currentActiveEditors: [], currentTemplateVersion: .zero))
        )
    }
    .environment(
        \.houseworkTemplateContext,
        .init(
            metadata: .init(templateId: "", name: ""),
            houseworkTemplate: [
                .init(dayOfWeek: .monday, items: []),
            ]
        )
    )
    .environment(HouseworkTemplateListStore(selectedTemplateId: "id"))
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
            initialDraft: .constant(.init(days: templateData)),
            draft: .constant(.init()),
            editorContext: .constant(.init(
                currentActiveEditors: [
                    .init(id: "1", userName: "Aさん"),
                    .init(id: "2", userName: "Bさん"),
                ],
                currentTemplateVersion: .zero
            ))
        )
    }
    .environment(
        \.houseworkTemplateContext,
        .init(
            metadata: .init(templateId: "", name: ""),
            houseworkTemplate: [
                .init(dayOfWeek: .monday, items: []),
            ]
        )
    )
    .environment(HouseworkTemplateListStore(selectedTemplateId: "id"))
    .apply(theme: .init())
}
#endif
