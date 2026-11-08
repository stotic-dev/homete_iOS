//
//  PaywallCompletedContent.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 購入（または復元）が完了したときのお礼
struct PaywallCompletedContent: View {

    let onTapClose: () -> Void

    var body: some View {
        ZStack {
            content
            // 購入を祝って、クラッカーを鳴らして花吹雪を降らせる
            CelebrationEffectView()
        }
    }

}

// MARK: UI定義

private extension PaywallCompletedContent {

    var content: some View {
        // 大きな文字で画面に収まらなくても読み切れるよう、丸ごとスクロールさせる
        ScrollView {
            VStack(spacing: .space32) {
                VStack(spacing: .space16) {
                    PaywallCrownEmblem()
                    Text("ありがとうございます", bundle: #bundle)
                        .font(with: .headLineM)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("プレミアムプランの特典が使えるようになりました。", bundle: #bundle)
                        .font(with: .body)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                Button {
                    onTapClose()
                } label: {
                    Text("閉じる", bundle: #bundle)
                        .padding(.vertical, .space8)
                        .frame(maxWidth: .infinity)
                }
                .primaryButtonStyle()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, .space16)
            .padding(.top, .space32)
            .padding(.bottom, .space24)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

}

#Preview("PaywallCompletedContent") {
    PaywallCompletedContent(onTapClose: {})
}
