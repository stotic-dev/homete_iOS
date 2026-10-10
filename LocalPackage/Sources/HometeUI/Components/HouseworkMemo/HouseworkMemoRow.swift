//
//  HouseworkMemoRow.swift
//  LocalPackage
//

import HometeResources
import SwiftUI

/// 家事・テンプレート・いつもの家事の入力画面に置く、メモの編集シートを開く行
public struct HouseworkMemoRow: View {

    let hasContent: Bool
    let titleFont: DesignSystem.Font
    let onTap: () -> Void

    /// - Parameters:
    ///   - hasContent: メモに内容があるか
    ///   - titleFont: 「メモ」の見出しのフォント。並べるほかの入力欄の見出しに揃える
    public init(hasContent: Bool, titleFont: DesignSystem.Font, onTap: @escaping () -> Void) {
        self.hasContent = hasContent
        self.titleFont = titleFont
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: .space8) {
                Text("メモ", bundle: #bundle)
                    .font(with: titleFont)
                    .foregroundStyle(.onSurface)
                Spacer()
                (hasContent ? Text("あり", bundle: #bundle, comment: "メモが書かれているか") : Text(
                    "なし",
                    bundle: #bundle,
                    comment: "メモが書かれているか"
                ))
                .font(with: .body)
                .foregroundStyle(.onSurfaceVariant)
                Image(systemName: "chevron.right")
                    .font(with: .caption)
                    .foregroundStyle(.onSurfaceVariant)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}

#if DEBUG
#Preview("HouseworkMemoRow_なし", traits: .sizeThatFitsLayout) {
    HouseworkMemoRow(hasContent: false, titleFont: .body, onTap: {})
        .padding()
}

#Preview("HouseworkMemoRow_あり", traits: .sizeThatFitsLayout) {
    HouseworkMemoRow(hasContent: true, titleFont: .headLineS, onTap: {})
        .padding()
}
#endif
