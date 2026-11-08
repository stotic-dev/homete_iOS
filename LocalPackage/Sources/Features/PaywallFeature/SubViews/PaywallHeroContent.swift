//
//  PaywallHeroContent.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// Paywallの一番上の見出し
struct PaywallHeroContent: View {

    var body: some View {
        VStack(spacing: .space8) {
            PaywallCrownEmblem()
            Text("プレミアムプラン", bundle: #bundle)
                .font(with: .headLineL)
                .foregroundStyle(.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text("家事の記録が、もっと便利になります。", bundle: #bundle)
                .font(with: .body)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

}

#Preview("PaywallHeroContent", traits: .sizeThatFitsLayout) {
    PaywallHeroContent()
        .padding()
}
