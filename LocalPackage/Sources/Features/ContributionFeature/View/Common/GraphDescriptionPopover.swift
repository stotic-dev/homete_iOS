//
//  GraphDescriptionPopover.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/08.
//

import SwiftUI

struct GraphDescriptionPopoverButton: View {
    
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    
    @State var isShowPopover = false

    var body: some View {
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

#Preview("GraphDescriptionPopoverButton_ポップアップ非表示", traits: .sizeThatFitsLayout) {
    GraphDescriptionPopoverButton(
        title: "家事達成割合とは？",
        message: """
        指定期間中において、達成した家事の数の合計からグループ内のユーザーの割合を示しています。
        達成した家事の数の観点から、家事貢献度を図ることができます。
        """
    )
}

#Preview("GraphDescriptionPopoverButton_ポップアップ表示", traits: .sizeThatFitsLayout) {
    GraphDescriptionPopoverButton(
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
