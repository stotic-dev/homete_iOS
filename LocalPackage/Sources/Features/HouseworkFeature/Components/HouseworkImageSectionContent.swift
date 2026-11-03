//
//  HouseworkImageSectionContent.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 画像をどこから選ぶか
enum HouseworkImagePickSource: Identifiable {

    /// フォトライブラリから選ぶ
    case library
    /// カメラで撮る
    case camera

    var id: Self {
        self
    }

}

/// 家事詳細・家事を追加する画面の、画像の欄
struct HouseworkImageSectionContent<Item: Identifiable, Thumbnail: View>: View {

    let images: [Item]
    let addState: HouseworkImageAddState
    /// カメラで撮る項目を出すか（カメラの無い端末・シミュレータでは出さない）
    let isCameraAvailable: Bool
    /// サムネイルをタップしたときの操作。VoiceOverで読み上げる
    let thumbnailAccessibilityLabel: LocalizedStringResource
    /// 追加ボタンの代わりに添える説明。くり返す家事のように、画像を添えられない理由を伝えるときに使う
    var note: LocalizedStringResource?
    let onTapImage: (Item.ID) -> Void
    let onTapAdd: (HouseworkImagePickSource) -> Void
    let onTapPremium: () -> Void
    @ViewBuilder let thumbnail: (Item) -> Thumbnail

    var body: some View {
        SectionCard(.localized("画像")) {
            if !images.isEmpty {
                imageGrid()
            }
            if !images.isEmpty, addState != .hidden || note != nil {
                Divider()
            }
            addRow()
            if let note {
                Text(note)
                    .font(with: .caption)
                    .foregroundStyle(.textSecondary)
            }
        }
    }

}

// MARK: - UI定義

private extension HouseworkImageSectionContent {

    func imageGrid() -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: .space8)], spacing: .space8) {
            ForEach(images) { image in
                Button {
                    onTapImage(image.id)
                } label: {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            thumbnail(image)
                        }
                        .cornerRadius(.radius12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(thumbnailAccessibilityLabel)
            }
        }
    }

    @ViewBuilder
    func addRow() -> some View {
        switch addState {
        case let .available(remainingCount):
            HStack(spacing: .space8) {
                addMenu()
                Spacer()
                Text("あと\(remainingCount)枚", bundle: #bundle, comment: "家事に添えられる残りの画像の枚数")
                    .font(with: .caption)
                    .foregroundStyle(.textSecondary)
            }

        case .limitReached:
            Text("画像は\(HouseworkImagePolicy.maxImageCount)枚まで添えられます", bundle: #bundle)
                .font(with: .caption)
                .foregroundStyle(.textSecondary)

        case .premiumRequired:
            premiumButton()

        case .hidden:
            EmptyView()
        }
    }

    func addMenu() -> some View {
        Menu {
            Button(.localized("写真を選ぶ"), systemImage: "photo.on.rectangle") {
                onTapAdd(.library)
            }
            if isCameraAvailable {
                Button(.localized("写真を撮る"), systemImage: "camera") {
                    onTapAdd(.camera)
                }
            }
        } label: {
            Label(.localized("画像を追加"), systemImage: "plus")
                .font(with: .body)
        }
    }

    /// 無料プランでも追加ボタンを出し、プレミアムプランで使えることが分かるようにする
    func premiumButton() -> some View {
        Button {
            onTapPremium()
        } label: {
            HStack(spacing: .space8) {
                Label(.localized("画像を追加"), systemImage: "plus")
                    .font(with: .body)
                Spacer()
                Label(.localized("プレミアムプラン"), systemImage: "crown.fill")
                    .font(with: .caption)
                    .foregroundStyle(.textSecondary)
            }
            .contentShape(Rectangle())
        }
        .accessibilityHint(.localized("プレミアムプランで使えます"))
    }

}

#if DEBUG
/// Preview用の、画像の欄に並べる1枚
struct HouseworkImagePreviewItem: Identifiable {

    let id: Int

}

#Preview("HouseworkImageSectionContent_画像なし", traits: .sizeThatFitsLayout) {
    HouseworkImageSectionContent(
        images: [HouseworkImagePreviewItem](),
        addState: .available(remainingCount: 10),
        isCameraAvailable: true,
        thumbnailAccessibilityLabel: .localized("画像を拡大して見る"),
        onTapImage: { _ in },
        onTapAdd: { _ in },
        onTapPremium: {},
        thumbnail: { _ in EmptyView() }
    )
    .padding()
}

#Preview("HouseworkImageSectionContent_画像あり", traits: .sizeThatFitsLayout) {
    HouseworkImageSectionContent(
        images: (0 ..< 3).map { HouseworkImagePreviewItem(id: $0) },
        addState: .available(remainingCount: 7),
        isCameraAvailable: true,
        thumbnailAccessibilityLabel: .localized("画像を拡大して見る"),
        onTapImage: { _ in },
        onTapAdd: { _ in },
        onTapPremium: {},
        thumbnail: { _ in
            HouseworkImageContent(phase: .loaded(.makeForPreview(width: 160, height: 120)), contentMode: .fill)
        }
    )
    .padding()
}

#Preview("HouseworkImageSectionContent_上限", traits: .sizeThatFitsLayout) {
    HouseworkImageSectionContent(
        images: (0 ..< 10).map { HouseworkImagePreviewItem(id: $0) },
        addState: .limitReached,
        isCameraAvailable: true,
        thumbnailAccessibilityLabel: .localized("画像を拡大して見る"),
        onTapImage: { _ in },
        onTapAdd: { _ in },
        onTapPremium: {},
        thumbnail: { _ in
            HouseworkImageContent(phase: .loaded(.makeForPreview(width: 160, height: 120)), contentMode: .fill)
        }
    )
    .padding()
}

#Preview("HouseworkImageSectionContent_無料プラン", traits: .sizeThatFitsLayout) {
    HouseworkImageSectionContent(
        images: [HouseworkImagePreviewItem](),
        addState: .premiumRequired,
        isCameraAvailable: true,
        thumbnailAccessibilityLabel: .localized("画像を拡大して見る"),
        onTapImage: { _ in },
        onTapAdd: { _ in },
        onTapPremium: {},
        thumbnail: { _ in EmptyView() }
    )
    .padding()
}

#Preview("HouseworkImageSectionContent_閲覧のみ", traits: .sizeThatFitsLayout) {
    HouseworkImageSectionContent(
        images: (0 ..< 2).map { HouseworkImagePreviewItem(id: $0) },
        addState: .hidden,
        isCameraAvailable: true,
        thumbnailAccessibilityLabel: .localized("画像を拡大して見る"),
        onTapImage: { _ in },
        onTapAdd: { _ in },
        onTapPremium: {},
        thumbnail: { _ in HouseworkImageContent(phase: .failed, contentMode: .fill) }
    )
    .padding()
}

#Preview("HouseworkImageSectionContent_くり返す家事", traits: .sizeThatFitsLayout) {
    HouseworkImageSectionContent(
        images: [HouseworkImagePreviewItem](),
        addState: .hidden,
        isCameraAvailable: true,
        thumbnailAccessibilityLabel: .localized("画像を拡大して見る"),
        note: .localized("くり返す家事には、画像を添えられません"),
        onTapImage: { _ in },
        onTapAdd: { _ in },
        onTapPremium: {},
        thumbnail: { _ in EmptyView() }
    )
    .padding()
}
#endif
