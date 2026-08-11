//
//  RemoveAdsPromotionLink.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/08/11.
//

import HometeUI
import SwiftUI

/// 広告バナーの直下に表示する、Paywallへの導線リンク
struct RemoveAdsPromotionLink: View {

    let action: () -> Void

    var body: some View {
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
            .frame(maxWidth: .infinity)
        }
    }

}

#Preview(traits: .sizeThatFitsLayout) {
    RemoveAdsPromotionLink {}
}
