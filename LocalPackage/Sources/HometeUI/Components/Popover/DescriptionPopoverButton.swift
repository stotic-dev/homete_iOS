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

    let title: LocalizedStringKey
    let message: LocalizedStringKey

    @State var isShowPopover: Bool

    public init(title: LocalizedStringKey, message: LocalizedStringKey) {
        self.init(title: title, message: message, isShowPopover: false)
    }

    init(title: LocalizedStringKey, message: LocalizedStringKey, isShowPopover: Bool) {
        self.title = title
        self.message = message
        // @Stateは他のプロパティを初期化してから代入する（iOS 27 SDKで@Stateがマクロになったため）
        self.isShowPopover = isShowPopover
    }

    public var body: some View {
        Button {
            isShowPopover = true
        } label: {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.secondary)
        }
        .popover(isPresented: $isShowPopover) {
            VStack(alignment: .leading, spacing: .space8) {
                Text(title)
                    .font(with: .headLineS)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(message)
                    .font(with: .caption)
                    .foregroundStyle(.onSubSurface)
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
