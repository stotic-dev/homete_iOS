//
//  HouseworkImageViewerView.swift
//  LocalPackage
//

import HometeModel
import HometeUI
import SwiftUI

/// 家事に添えた画像の拡大表示
/// - Note: 左右にスワイプして、同じ家事のほかの画像に切り替えられる
public struct HouseworkImageViewerView<Page: View>: View {

    let images: [HouseworkImage]
    @Binding var selectedId: HouseworkImage.ID
    /// 消せる画像のID（プレミアムプランなら全部、無料プランなら自分が追加した画像だけ）
    let deletableIds: Set<HouseworkImage.ID>
    let onTapClose: () -> Void
    let onTapDelete: (HouseworkImage) -> Void
    @ViewBuilder let page: (HouseworkImage) -> Page

    public init(
        images: [HouseworkImage],
        selectedId: Binding<HouseworkImage.ID>,
        deletableIds: Set<HouseworkImage.ID>,
        onTapClose: @escaping () -> Void,
        onTapDelete: @escaping (HouseworkImage) -> Void,
        @ViewBuilder page: @escaping (HouseworkImage) -> Page
    ) {
        self.images = images
        _selectedId = selectedId
        self.deletableIds = deletableIds
        self.onTapClose = onTapClose
        self.onTapDelete = onTapDelete
        self.page = page
    }

    public var body: some View {
        TabView(selection: $selectedId) {
            ForEach(images) { image in
                page(image)
                    .tag(image.id)
            }
        }
        #if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        #endif
        .background(.backgroundScreen)
        .navigationTitle(pageTitle)
        .inlineNavigationBarTitleDisplayMode()
        .leadingToolbarItem {
            NavigationBarButton(label: .close) {
                onTapClose()
            }
        }
        .trailingToolbarItem {
            if let selectedImage, deletableIds.contains(selectedImage.id) {
                NavigationBarButton(label: .delete) {
                    onTapDelete(selectedImage)
                }
            }
        }
    }

}

// MARK: - 表示内容

private extension HouseworkImageViewerView {

    var selectedImage: HouseworkImage? {
        images.first { $0.id == selectedId }
    }

    /// 何枚目かを見出しに出す
    var pageTitle: LocalizedStringResource {
        let index = images.firstIndex { $0.id == selectedId } ?? 0
        return .localized(
            "\(index + 1) / \(images.count)",
            comment: "拡大表示している画像が、家事に添えた画像の何枚目か"
        )
    }

}

#if DEBUG
#Preview("HouseworkImageViewerView_消せる") {
    NavigationStack {
        HouseworkImageViewerView(
            images: [
                .init(id: "1", storagePath: "path1", uploaderId: "userA"),
                .init(id: "2", storagePath: "path2", uploaderId: "userB"),
            ],
            selectedId: .constant("1"),
            deletableIds: ["1"],
            onTapClose: {},
            onTapDelete: { _ in },
            page: { _ in
                HouseworkImageContent(phase: .loaded(.makeForPreview(width: 300, height: 400)), contentMode: .fit)
            }
        )
    }
}

#Preview("HouseworkImageViewerView_消せない") {
    NavigationStack {
        HouseworkImageViewerView(
            images: [
                .init(id: "1", storagePath: "path1", uploaderId: "userA"),
                .init(id: "2", storagePath: "path2", uploaderId: "userB"),
            ],
            selectedId: .constant("2"),
            deletableIds: ["1"],
            onTapClose: {},
            onTapDelete: { _ in },
            page: { _ in
                HouseworkImageContent(phase: .loaded(.makeForPreview(width: 400, height: 300)), contentMode: .fit)
            }
        )
    }
}
#endif
