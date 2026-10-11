//
//  DescriptionPopoverButton.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/08.
//

import SwiftUI
#if canImport(Prefire)
import Prefire
#endif

/// 項目の意味をポップアップで説明する「？」ボタン
public struct DescriptionPopoverButton: View {

    let title: LocalizedStringResource
    let message: LocalizedStringResource

    @State var isShowPopover: Bool

    public init(title: LocalizedStringResource, message: LocalizedStringResource) {
        self.init(title: title, message: message, isShowPopover: false)
    }

    init(title: LocalizedStringResource, message: LocalizedStringResource, isShowPopover: Bool) {
        self.title = title
        self.message = message
        // @Stateは他のプロパティを初期化してから代入する（iOS 27 SDKで@Stateがマクロになったため）
        self.isShowPopover = isShowPopover
    }

    public var body: some View {
        Button {
            isShowPopover = true
        } label: {
            // 親の`.tint`に引きずられて置き場所ごとに色が変わらないよう、fillAccentを基準に固定する。
            // Color.accentColorはVRTのホストアプリにAccentColorがなく、スナップショットだけ青になるため使わない
            Image(systemName: "questionmark.circle")
                .foregroundStyle(Color.fillAccent.secondary)
        }
        .popover(isPresented: $isShowPopover) {
            VStack(alignment: .leading, spacing: .space8) {
                Text(title)
                    .font(with: .headLineS)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(message)
                    .font(with: .caption)
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.leading)
            }
            .padding(.space16)
            .frame(width: 200)
            .presentationCompactAdaptation(.popover)
        }
    }

}

#Preview("DescriptionPopoverButton_ポップアップ非表示", traits: .sizeThatFitsLayout) {
    DescriptionPopoverButton(
        title: "家事達成割合とは？",
        message: """
        指定期間中において、達成した家事の数の合計からグループ内のユーザーの割合を示しています。
        達成した家事の数の観点から、家事貢献度を図ることができます。
        """
    )
}

#Preview("DescriptionPopoverButton_ポップアップ表示", traits: .sizeThatFitsLayout) {
    DescriptionPopoverButton(
        title: "家事達成割合とは？",
        message: """
        指定期間中において、達成した家事の数の合計からグループ内のユーザーの割合を示しています。
        達成した家事の数の観点から、家事貢献度を図ることができます。
        """,
        isShowPopover: true
    )
    #if canImport(Prefire)
    .prefireIgnored()
    #endif
}
