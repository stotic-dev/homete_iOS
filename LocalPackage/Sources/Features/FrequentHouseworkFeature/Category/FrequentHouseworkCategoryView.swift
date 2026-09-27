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
        .navigationTitle("カテゴリ")
        .inlineNavigationBarTitleDisplayMode()
        .trailingToolbarItem {
            trailingNavigationItem()
        }
        .trackScreenView(.frequentHouseworkCategory)
    }

}

// MARK: - UI定義

private extension FrequentHouseworkCategoryView {

    func presetSection() -> some View {
        Section("あらかじめ用意しているカテゴリ") {
            ForEach(PresetFrequentHouseworkCategory.allCases, id: \.self) { preset in
                HStack(spacing: .space8) {
                    Text(preset.name)
                        .font(with: .body)
                        .foregroundStyle(.onSurface)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.onSurfaceVariant)
                        .accessibilityLabel("名前の変更と削除はできません")
                }
            }
            .deleteDisabled(true)
            .moveDisabled(true)
        }
    }

    func customSection() -> some View {
        Section("追加したカテゴリ") {
            if customCategories.isEmpty {
                Text("カテゴリを追加すると、いつもの家事をカテゴリごとにまとめられます。")
                    .font(with: .caption)
                    .foregroundStyle(.onSurfaceVariant)
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
                    .foregroundStyle(.onSurface)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    func trailingNavigationItem() -> some View {
        HStack(spacing: .space8) {
            #if os(iOS)
            if !customCategories.isEmpty {
                EditButton()
            }
            #endif
            Button {
                onTapAdd()
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("カテゴリを追加")
        }
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
