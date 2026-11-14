//
//  PaywallHeroContent.swift
//  LocalPackage
//

import HometeModel
import HometeUI
import SwiftUI

/// Paywallの一番上の見出し
public struct PaywallHeroContent: View {

    public init() {}

    public var body: some View {
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
