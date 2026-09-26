//
//  FrequentHouseworkManagementView.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// いつもの家事の管理画面（カテゴリごとのセクションで一覧表示する）
struct FrequentHouseworkManagementView: View {

    /// いつもの家事・カテゴリの読み込み状態
    /// - Note: 読み込み済みになるまでは件数上限・名前の重複・カテゴリを正しく判定できないため、一覧も追加も出さない
    let loadState: ListenerLoadState
    let sections: [FrequentHouseworkSection]
    /// 上限を超えていて使えない家事のID
    let unusableItemIds: Set<String>
    /// 無料プランの件数と上限。プレミアムプランでは`nil`
    let limitStatus: FrequentHouseworkLimitStatus?
    let onTapClose: () -> Void
    let onTapAdd: () -> Void
    let onTapItem: (FrequentHouseworkItem) -> Void
    let onDelete: (FrequentHouseworkItem) -> Void
    /// カテゴリ内で並べ替えた後の家事IDの順
    let onMove: ([String]) -> Void
    let onTapUpgrade: () -> Void
    let onRetry: () -> Void

    var body: some View {
        content()
            .navigationTitle("いつもの家事")
            .inlineNavigationBarTitleDisplayMode()
            .leadingToolbarItem {
                NavigationBarButton(label: .close) {
                    onTapClose()
                }
            }
            .trailingToolbarItem {
                trailingNavigationItem()
            }
            .trackScreenView(.frequentHouseworkManagement)
    }

}

// MARK: - UI定義

private extension FrequentHouseworkManagementView {

    @ViewBuilder
    func content() -> some View {
        switch loadState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case let .failed(error):
            LoadErrorView(error: error) {
                onRetry()
            }
            .padding(.horizontal, .space16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded:
            loadedContent()
        }
    }

    @ViewBuilder
    func loadedContent() -> some View {
        if sections.isEmpty {
            FrequentHouseworkEmptyView {
                onTapAdd()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            itemList()
        }
    }

    func itemList() -> some View {
        List {
            if let limitStatus {
                Section {
                    FrequentHouseworkLimitHeader(status: limitStatus) {
                        onTapUpgrade()
                    }
                }
            }
            ForEach(sections) { section in
                Section(section.category.name) {
                    ForEach(section.items) { item in
                        itemRow(item, isUsable: !unusableItemIds.contains(item.id))
                    }
                    .onDelete { offsets in
                        offsets.map { section.items[$0] }.forEach(onDelete)
                    }
                    .onMove { source, destination in
                        var orderedIds = section.items.map(\.id)
                        orderedIds.move(fromOffsets: source, toOffset: destination)
                        onMove(orderedIds)
                    }
                }
            }
        }
    }

    func itemRow(_ item: FrequentHouseworkItem, isUsable: Bool) -> some View {
        Button {
            onTapItem(item)
        } label: {
            HStack(spacing: .space8) {
                VStack(alignment: .leading, spacing: .space4) {
                    Text(item.title)
                        .font(with: .body)
                        .foregroundStyle(.onSurface)
                    if !isUsable {
                        Text("プレミアムプランで使えます")
                            .font(with: .caption)
                            .foregroundStyle(.onSurfaceVariant)
                    }
                }
                Spacer()
                PointLabel(point: item.point)
            }
            .opacity(isUsable ? 1 : 0.5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func trailingNavigationItem() -> some View {
        if loadState == .loaded {
            HStack(spacing: .space8) {
                #if os(iOS)
                if !sections.isEmpty {
                    EditButton()
                }
                #endif
                Button {
                    onTapAdd()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("いつもの家事を追加")
            }
        }
    }

}

#if DEBUG
#Preview("FrequentHouseworkManagementView_無料プラン") {
    let items: [FrequentHouseworkItem] = [
        .makeForPreview(id: "1", title: "風呂掃除", categoryId: "preset.cleaning"),
        .makeForPreview(id: "2", title: "換気扇", point: 30, categoryId: "preset.cleaning", sortOrder: 1),
        .makeForPreview(id: "3", title: "布団干し", point: 20, categoryId: "preset.laundry"),
        .makeForPreview(id: "4", title: "ゴミ出し"),
    ]
    NavigationStack {
        FrequentHouseworkManagementView(
            loadState: .loaded,
            sections: FrequentHouseworkContext(items: items).sections,
            unusableItemIds: ["4"],
            limitStatus: .init(count: 11, limit: 10),
            onTapClose: {},
            onTapAdd: {},
            onTapItem: { _ in },
            onDelete: { _ in },
            onMove: { _ in },
            onTapUpgrade: {},
            onRetry: {}
        )
    }
}

#Preview("FrequentHouseworkManagementView_未登録") {
    NavigationStack {
        FrequentHouseworkManagementView(
            loadState: .loaded,
            sections: [],
            unusableItemIds: [],
            limitStatus: nil,
            onTapClose: {},
            onTapAdd: {},
            onTapItem: { _ in },
            onDelete: { _ in },
            onMove: { _ in },
            onTapUpgrade: {},
            onRetry: {}
        )
    }
}

#Preview("FrequentHouseworkManagementView_読み込み失敗") {
    NavigationStack {
        FrequentHouseworkManagementView(
            loadState: .failed(.noNetwork),
            sections: [],
            unusableItemIds: [],
            limitStatus: nil,
            onTapClose: {},
            onTapAdd: {},
            onTapItem: { _ in },
            onDelete: { _ in },
            onMove: { _ in },
            onTapUpgrade: {},
            onRetry: {}
        )
    }
}
#endif
