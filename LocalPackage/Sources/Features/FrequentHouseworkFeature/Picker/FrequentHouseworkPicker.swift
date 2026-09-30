//
//  FrequentHouseworkPicker.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 登録済みのいつもの家事をカテゴリで絞り込んで選ぶ部品
/// - Note: 何を選べるかは呼び出し側が`FrequentHouseworkContext`と`FrequentHouseworkLimitPolicy`から決めて渡す。
///         この部品は渡された値を描画してタップを伝えるだけにする
public struct FrequentHouseworkPicker: View {

    /// 絞り込みに並べるカテゴリ（先頭の「すべて」は部品側で足す）
    let filterCategories: [FrequentHouseworkCategory]
    /// カテゴリごとに分けたいつもの家事
    let sections: [FrequentHouseworkSection]
    let selectedIds: Set<String>
    /// 無料プランの上限を超えていて選べない家事のID
    let disabledIds: Set<String>
    let onTapItem: (FrequentHouseworkItem) -> Void
    let onTapManage: () -> Void

    /// 絞り込みで選んでいるカテゴリのID。`nil`は「すべて」
    /// - Note: 表示だけの状態なので部品の内部に持つ
    @State var selectedCategoryId: String?

    public init(
        filterCategories: [FrequentHouseworkCategory],
        sections: [FrequentHouseworkSection],
        selectedIds: Set<String>,
        disabledIds: Set<String>,
        selectedCategoryId: String? = nil,
        onTapItem: @escaping (FrequentHouseworkItem) -> Void,
        onTapManage: @escaping () -> Void
    ) {
        self.filterCategories = filterCategories
        self.sections = sections
        self.selectedIds = selectedIds
        self.disabledIds = disabledIds
        self.onTapItem = onTapItem
        self.onTapManage = onTapManage
        _selectedCategoryId = State(initialValue: selectedCategoryId)
    }

    public var body: some View {
        if sections.isEmpty {
            emptyContent()
        } else {
            registeredContent()
        }
    }

}

// MARK: - UI定義

private extension FrequentHouseworkPicker {

    var displayedItems: [FrequentHouseworkItem] {
        guard let selectedCategoryId else { return sections.flatMap(\.items) }
        return sections.filter { $0.category.id == selectedCategoryId }.flatMap(\.items)
    }

    /// - Note: 管理の導線は、この部品を出す画面のナビゲーションバーに置く
    func registeredContent() -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            categoryFilter()
            itemGrid()
        }
    }

    /// - Note: タブのスワイプより横スクロールを優先させるため、カテゴリだけを横`ScrollView`に入れる
    func categoryFilter() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .space8) {
                categoryChip(id: nil, name: "すべて")
                ForEach(filterCategories) { category in
                    categoryChip(id: category.id, name: category.name)
                }
            }
            .padding(.horizontal, .space16)
        }
    }

    func categoryChip(id: String?, name: String) -> some View {
        let isSelected = selectedCategoryId == id
        return Button {
            selectedCategoryId = id
        } label: {
            Text(name)
                .font(with: .caption)
                .foregroundStyle(isSelected ? .onPrimary1 : .onSurface)
                .padding(.horizontal, .space16)
                .frame(minHeight: 32)
                .background {
                    RoundedRectangle(radius: .radius8)
                        .fill(isSelected ? Color.primary1 : Color.primary3)
                }
        }
        .buttonStyle(.plain)
    }

    func itemGrid() -> some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 150), spacing: .space8)],
                alignment: .leading,
                spacing: .space8
            ) {
                ForEach(displayedItems) { item in
                    FrequentHouseworkChip(
                        item: item,
                        isSelected: selectedIds.contains(item.id),
                        isUsable: !disabledIds.contains(item.id)
                    ) {
                        onTapItem(item)
                    }
                }
            }
            .padding(.horizontal, .space16)
            // 最後の行が、呼び出し側が右下に浮かせるボタンに隠れないようにする
            .padding(.bottom, .space64)
        }
    }

    func emptyContent() -> some View {
        VStack(spacing: .space16) {
            Text("いつもの家事を登録しませんか？")
                .font(with: .headLineS)
            Text("よくやる家事を登録しておくと、次からタップするだけで追加できます。")
                .font(with: .body)
                .multilineTextAlignment(.center)
            Button("いつもの家事を登録する") {
                onTapManage()
            }
            .primaryButtonStyle()
        }
        .padding(.horizontal, .space16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

}

#if DEBUG
#Preview("FrequentHouseworkPicker_登録あり") {
    let items: [FrequentHouseworkItem] = [
        .makeForPreview(id: "1", title: "風呂掃除", categoryId: "preset.cleaning"),
        .makeForPreview(id: "2", title: "換気扇", point: 30, categoryId: "preset.cleaning", sortOrder: 1),
        .makeForPreview(id: "3", title: "布団干し", point: 20, categoryId: "preset.laundry"),
        .makeForPreview(id: "4", title: "ゴミ出し"),
    ]
    let context = FrequentHouseworkContext(items: items)
    FrequentHouseworkPicker(
        filterCategories: context.sections.map(\.category),
        sections: context.sections,
        selectedIds: ["1", "3"],
        disabledIds: ["4"],
        onTapItem: { _ in },
        onTapManage: {}
    )
}

#Preview("FrequentHouseworkPicker_未登録") {
    FrequentHouseworkPicker(
        filterCategories: [],
        sections: [],
        selectedIds: [],
        disabledIds: [],
        onTapItem: { _ in },
        onTapManage: {}
    )
}
#endif
