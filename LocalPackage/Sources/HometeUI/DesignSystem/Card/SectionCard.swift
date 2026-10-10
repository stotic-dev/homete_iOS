//
//  SectionCard.swift
//  LocalPackage
//

import HometeResources
import SwiftUI

/// セクションの見出しと、中身をひとまとまりに見せるカード
///
/// 中身の項目は`.space16`の間隔で縦に並べる。項目の区切りに線が要るときは、呼び出し側で`Divider()`を挟む。
/// - Note: 見出しの字下げは、カードの中の文字の位置に揃える
public struct SectionCard<Content: View>: View {

    let title: LocalizedStringResource
    let onTapBackground: (() -> Void)?
    let content: Content

    /// - Parameters:
    ///   - title: セクションの見出し
    ///   - content: カードの中身
    ///   - onTapBackground: カードの中の何もない所をタップしたときの処理。入力欄の外をタップしたら入力を終える、といった用途に使う
    /// - Note: `onTapBackground`は中身より後ろに置き、`SectionCard("見出し") { ... } onTapBackground: { ... }`と書けるようにする
    public init(
        _ title: LocalizedStringResource,
        @ViewBuilder content: () -> Content,
        onTapBackground: (() -> Void)? = nil
    ) {
        self.title = title
        self.onTapBackground = onTapBackground
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text(title)
                .font(with: .boldCaption)
                .foregroundStyle(.onSurfaceVariant)
                .padding(.horizontal, .space16)
                .accessibilityAddTraits(.isHeader)
            card()
        }
    }

}

// MARK: - UI定義

private extension SectionCard {

    @ViewBuilder
    func card() -> some View {
        let stack = VStack(alignment: .leading, spacing: .space16) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        if let onTapBackground {
            stack.sectionCardStyle(onTapBackground: onTapBackground)
        } else {
            stack.sectionCardStyle()
        }
    }

}

#Preview("SectionCard", traits: .sizeThatFitsLayout) {
    VStack(spacing: .space24) {
        SectionCard("セクションタイトル") {
            Text("1つ目の項目")
                .font(with: .body)
            Divider()
            Text("2つ目の項目")
                .font(with: .body)
        }
        SectionCard("別のセクション") {
            Text("セクションの内容")
                .font(with: .body)
        }
    }
    .padding(.space16)
}
