//
//  PromoteHouseworkTemplateBanner.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/04.
//

import SwiftUI

struct PromoteHouseworkTemplateBanner: View {
    
    var body: some View {
        VStack(alignment: .center, spacing: DesignSystem.Space.space24) {
            Image(.promoteHouseworkTemplateBannerIcon)
                .resizable()
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(.radius8)
            VStack(spacing: DesignSystem.Space.space8) {
                Text("家事のテンプレートが設定されていません")
                    .font(with: .headLineS)
                Text("家事のテンプレートを設定して、家事を分担しましょう！")
                    .font(with: .body)
                    .multilineTextAlignment(.center)
            }
            Button("テンプレートを設定する") {
                // TODO: テンプレート設定画面へ遷移
            }
            .primaryButtonStyle()
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    PromoteHouseworkTemplateBanner()
}
