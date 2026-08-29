//
//  RemoveAdsPromotionLink.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/08/11.
//

import HometeResources
import SwiftUI

/// 広告バナーの直下に表示する、Paywallへの導線リンク
public struct RemoveAdsPromotionLink: View {

    let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: .space4) {
                Text("広告を非表示にする")
                    .font(with: .boldCaption)
                Image(systemName: "chevron.right")
                    .font(with: .caption)
            }
            .foregroundStyle(.primary2)
            // テキストリンク風の見た目のまま、タップ領域だけHIG推奨の44pt四方を確保する
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
    }

}

#Preview(traits: .sizeThatFitsLayout) {
    RemoveAdsPromotionLink {}
}
