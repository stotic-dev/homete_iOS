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
        // 大きな文字で画面に収まらなくても読み切れるよう、丸ごとスクロールさせる
        ScrollView {
            VStack(spacing: .space32) {
                VStack(spacing: .space16) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.iconDecorative)
                        .accessibilityHidden(true)
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
            .padding(.top, .space64)
            .padding(.bottom, .space24)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

}

#Preview("PaywallCompletedContent") {
    PaywallCompletedContent(onTapClose: {})
}
