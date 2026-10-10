//
//  FrequentHouseworkCategoryView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// いつもの家事のカテゴリを管理する画面
/// - Note: プリセットは変更できないため、一覧に出すだけにする
struct FrequentHouseworkCategoryView: View {

    #if os(iOS)
    /// 並べ替え・削除の編集モード
    /// - Note: ツールバーの出し分けに使うため、`EditButton`任せにせずこの画面で持つ
    @State var editMode = EditMode.inactive
    #endif

    /// 並べ替え順のカスタムカテゴリ
    let customCategories: [FrequentHouseworkCustomCategory]
    let onTapAdd: () -> Void
    let onTapCategory: (FrequentHouseworkCustomCategory) -> Void
    let onDelete: (FrequentHouseworkCustomCategory) -> Void
    /// 並べ替えた後のカスタムカテゴリIDの順
    let onMove: ([String]) -> Void

    var body: some View {
        List {
            presetSection()
            customSection()
        }
        .navigationTitle(.localized("カテゴリ"))
        .inlineNavigationBarTitleDisplayMode()
        .trailingToolbarItem {
            trailingNavigationItem()
        }
        // ツールバーの中身にも編集モードを伝えるため、ツールバーより外側で環境に載せる
        #if os(iOS)
        .environment(\.editMode, $editMode)
        #endif
        .trackScreenView(.frequentHouseworkCategory)
    }

}

// MARK: - UI定義

private extension FrequentHouseworkCategoryView {

    func presetSection() -> some View {
        Section(.localized("あらかじめ用意しているカテゴリ")) {
            ForEach(PresetFrequentHouseworkCategory.allCases, id: \.self) { preset in
                HStack(spacing: .space8) {
                    Text(preset.name)
                        .font(with: .body)
                        .foregroundStyle(.textPrimary)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.textSecondary)
                        .accessibilityLabel(.localized("名前の変更と削除はできません"))
                }
            }
            .deleteDisabled(true)
            .moveDisabled(true)
        }
    }

    func customSection() -> some View {
        Section(.localized("追加したカテゴリ")) {
            if customCategories.isEmpty {
                Text("カテゴリを追加すると、いつもの家事をカテゴリごとにまとめられます。", bundle: #bundle)
                    .font(with: .caption)
                    .foregroundStyle(.textSecondary)
            } else {
                ForEach(customCategories) { category in
                    categoryRow(category)
                }
                .onDelete { offsets in
                    offsets.map { customCategories[$0] }.forEach(onDelete)
                }
                .onMove { source, destination in
                    var orderedIds = customCategories.map(\.id)
                    orderedIds.move(fromOffsets: source, toOffset: destination)
                    onMove(orderedIds)
                }
            }
        }
    }

    func categoryRow(_ category: FrequentHouseworkCustomCategory) -> some View {
        Button {
            onTapCategory(category)
        } label: {
            HStack(spacing: .space8) {
                Text(category.name)
                    .font(with: .body)
                    .foregroundStyle(.textPrimary)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// - Note: 編集中は並べ替え・削除に使えない操作を出さず、「完了」だけにする
    func trailingNavigationItem() -> some View {
        HStack(spacing: .space8) {
            #if os(iOS)
            if !customCategories.isEmpty {
                EditButton()
            }
            #endif
            if !isEditing {
                Button {
                    onTapAdd()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(.localized("カテゴリを追加"))
            }
        }
    }

    var isEditing: Bool {
        #if os(iOS)
        editMode.isEditing
        #else
        false
        #endif
    }

}

#if DEBUG
#Preview("FrequentHouseworkCategoryView_カスタムあり") {
    NavigationStack {
        FrequentHouseworkCategoryView(
            customCategories: [
                .makeForPreview(id: "1", name: "ペット"),
                .makeForPreview(id: "2", name: "庭", sortOrder: 1),
            ],
            onTapAdd: {},
            onTapCategory: { _ in },
            onDelete: { _ in },
            onMove: { _ in }
        )
    }
}

#Preview("FrequentHouseworkCategoryView_カスタムなし") {
    NavigationStack {
        FrequentHouseworkCategoryView(
            customCategories: [],
            onTapAdd: {},
            onTapCategory: { _ in },
            onDelete: { _ in },
            onMove: { _ in }
        )
    }
}
#endif
