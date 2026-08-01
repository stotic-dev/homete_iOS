//
//  PromoteHouseworkTemplateBanner.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/04.
//

import HometeResources
import HometeUI
import SwiftUI

struct PromoteHouseworkTemplateBanner: View {

    let action: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: .space24) {
            Image(.promoteHouseworkTemplateBannerIcon)
                .resizable()
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(.radius8)
            VStack(spacing: .space8) {
                Text("家事のテンプレートが設定されていません")
                    .font(with: .headLineS)
                Text("家事のテンプレートを設定して、家事を分担しましょう！")
                    .font(with: .body)
                    .multilineTextAlignment(.center)
            }
            Button("テンプレートを設定する") {
                action()
            }
            .primaryButtonStyle()
        }
    }

}

#Preview(traits: .sizeThatFitsLayout) {
    PromoteHouseworkTemplateBanner {}
}
