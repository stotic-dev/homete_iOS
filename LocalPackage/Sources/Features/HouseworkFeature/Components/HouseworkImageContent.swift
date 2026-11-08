//
//  HouseworkImageContent.swift
//  LocalPackage
//

import CoreGraphics
import HometeUI
import SwiftUI

/// 家事に添えた画像の読み込みの状態
enum HouseworkImagePhase {

    case loading
    case loaded(CGImage)
    case failed

}

/// 家事に添えた画像を1枚表示する
struct HouseworkImageContent: View {

    let phase: HouseworkImagePhase
    /// サムネイルは枠いっぱいに切り抜き（`.fill`）、拡大表示は全体が収まるように（`.fit`）出す
    let contentMode: ContentMode

    var body: some View {
        switch phase {
        case let .loaded(image):
            Image(decorative: image, scale: 1)
                .resizable()
                .aspectRatio(contentMode: contentMode)

        case .loading:
            placeholder(systemImage: "photo")

        case .failed:
            placeholder(systemImage: "exclamationmark.triangle")
                .accessibilityLabel(.localized("画像を読み込めませんでした"))
        }
    }

}

// MARK: - UI定義

private extension HouseworkImageContent {

    /// - Note: 読み込み中にスピナーを出すとVRTが撮るたびに変わるため、アイコンだけを出す
    func placeholder(systemImage: String) -> some View {
        Rectangle()
            .fill(.backgroundScreen)
            .overlay {
                Image(systemName: systemImage)
                    .font(with: .headLineS)
                    .foregroundStyle(.textSecondary)
            }
    }

}

#if DEBUG
#Preview("HouseworkImageContent_読み込み済み", traits: .fixedLayout(width: 120, height: 120)) {
    HouseworkImageContent(phase: .loaded(.makeForPreview(width: 160, height: 120)), contentMode: .fill)
        .frame(width: 120, height: 120)
        .clipped()
}

#Preview("HouseworkImageContent_読み込み中", traits: .fixedLayout(width: 120, height: 120)) {
    HouseworkImageContent(phase: .loading, contentMode: .fill)
}

#Preview("HouseworkImageContent_失敗", traits: .fixedLayout(width: 120, height: 120)) {
    HouseworkImageContent(phase: .failed, contentMode: .fill)
}
#endif
