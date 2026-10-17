//
//  HouseworkTemplateListContent.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 家事テンプレートの一覧（曜日・毎月のセクションと追加ボタン、保存ボタン）
///
/// 渡された編集中のテンプレートを描画して、操作を伝えるだけにとどめる。
/// ナビゲーションバーの右側の項目もここで並べるため、`NavigationStack`の中に置く。
struct HouseworkTemplateListContent: View {

    @Binding var collapsedDays: CollapsedHouseworkTemplateDays

    /// 編集中のテンプレート
    let draft: HouseworkTemplateDraft
    /// 保存していない変更があるか。あれば元に戻すボタンを出し、保存ボタンを押せるようにする
    let hasUnsavedChanges: Bool
    let onTapItem: (HouseworkTemplateItem) -> Void
    let onTapEdit: (HouseworkTemplateItem) -> Void
    /// - Parameter day: 毎週の家事を、この曜日からだけ外す。`nil`なら家事ごと消す
    let onTapDelete: (HouseworkTemplateItem.ItemId, _ day: DayOfWeek?) -> Void
    let onDropItem: (HouseworkTemplateItem.ItemId, _ destination: DayOfWeek) -> Void
    let onTapAdd: () -> Void
    let onTapReset: () -> Void
    let onTapSave: () -> Void

    var body: some View {
        ZStack {
            mainContent()
            addItemButton()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, .space24)
                // 直下に広告バナーが来るため、誤タップを防ぐ余白を取る
                .padding(.bottom, .space24)
        }
        #if os(iOS)
        .toolbar {
            trailingNavigationItem()
        }
        #endif
    }

}

// MARK: - メインコンテンツ

private extension HouseworkTemplateListContent {

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
                monthlySection(draft.displayedMonthlyItems)
            }
            .padding(.horizontal, .space16)
            .padding(.top, .space32)
            // 最後の項目が追加ボタンに隠れないよう、ボタンの高さと下の余白ぶん空ける
            .padding(.bottom, .space64 + .space24)
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
                    RoundedRectangle(radius: .radius12)
                        .fill(.backgroundCard)
                }
                .dropDestination(for: String.self) { ids, _ in
                    guard let droppedId = ids.first else { return false }
                    onDropItem(.init(id: droppedId), day)
                    return true
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .clipped()
    }

    func dayHeader(_ day: DayOfWeek, itemCount: Int, isCollapsed: Bool) -> some View {
        Button {
            withAnimation {
                collapsedDays.toggle(day)
            }
        } label: {
            HStack(spacing: .space8) {
                Image(systemName: "chevron.right")
                    .font(with: .caption)
                    .foregroundStyle(.textPrimary)
                    .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                Text(day.fullLabel)
                    .font(with: .headLineS)
                    .foregroundStyle(.textPrimary)
                if isCollapsed,
                   itemCount > 0 {
                    Text("(\(itemCount))")
                        .font(with: .caption)
                        .foregroundStyle(.textPrimary)
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .dropDestination(for: String.self) { ids, _ in
            guard let droppedId = ids.first else { return false }
            onDropItem(.init(id: droppedId), day)
            if isCollapsed {
                withAnimation {
                    collapsedDays.toggle(day)
                }
            }
            return true
        }
    }

    func emptyDayRow() -> some View {
        Text("家事なし", bundle: #bundle)
            .font(with: .caption)
            .foregroundStyle(.textPrimary)
            .padding(.vertical, .space8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    func itemRow(_ item: HouseworkTemplateItem, in day: DayOfWeek) -> some View {
        HouseworkTemplateItemRow(item: item)
            .contentShape(Rectangle())
            .onTapGesture {
                onTapItem(item)
            }
            .draggable(item.id.id)
            .contextMenu {
                Button(.localized("編集")) {
                    onTapEdit(item)
                }
                Button(.localized("削除"), role: .destructive) {
                    onTapDelete(item.id, day)
                }
            }
    }

    func monthlySection(_ monthlyItems: [HouseworkTemplateMonthlyItem]) -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("毎月", bundle: #bundle)
                .font(with: .headLineS)
                .foregroundStyle(.textPrimary)
            VStack(spacing: .space8) {
                if !monthlyItems.isEmpty {
                    ForEach(monthlyItems) { monthlyItem in
                        monthlyItemRow(monthlyItem)
                    }
                } else {
                    emptyDayRow()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.space8)
            .background {
                RoundedRectangle(radius: .radius12)
                    .fill(.backgroundCard)
            }
        }
    }

    /// 毎月の家事の行。曜日間のドラッグ&ドロップは毎週の家事だけの機能なので、ドラッグはできない
    func monthlyItemRow(_ monthlyItem: HouseworkTemplateMonthlyItem) -> some View {
        HouseworkTemplateItemRow(item: monthlyItem.item, recurrenceLabel: monthlyItem.rule.label)
            .contentShape(Rectangle())
            .onTapGesture {
                onTapItem(monthlyItem.item)
            }
            .contextMenu {
                Button(.localized("編集")) {
                    onTapEdit(monthlyItem.item)
                }
                Button(.localized("削除"), role: .destructive) {
                    onTapDelete(monthlyItem.id, nil)
                }
            }
    }

    func addItemButton() -> some View {
        Button {
            onTapAdd()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24))
        }
        .floatingButtonStyle()
    }

}

// MARK: - ナビゲーションバー

#if os(iOS)
private extension HouseworkTemplateListContent {

    @ToolbarContentBuilder
    func trailingNavigationItem() -> some ToolbarContent {
        if hasUnsavedChanges {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onTapReset()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .foregroundStyle(.textPrimary)
            }
        }
        if #available(iOS 26.0, *) {
            ToolbarSpacer()
        }
        ToolbarItem(placement: .topBarTrailing) {
            NavigationBarPrimaryActionButton(systemImage: "checkmark") {
                onTapSave()
            }
            .disabled(!hasUnsavedChanges)
        }
    }

}
#endif
