//
//  PromoteHouseworkTemplateBanner.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/04.
//

import HometeDomain
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
                .cornerRadius(.radius12)
            VStack(spacing: .space8) {
                Text("家事のテンプレートはまだありません", bundle: #bundle)
                    .font(with: .headLineS)
                Text("毎週やる家事をテンプレートにしておくと、家事ボードに自動で並びます", bundle: #bundle)
                    .font(with: .body)
                    .multilineTextAlignment(.center)
            }
            Button(.localized("テンプレートを設定する")) {
                action()
            }
            .primaryButtonStyle()
        }
    }

}

#Preview(traits: .sizeThatFitsLayout) {
    PromoteHouseworkTemplateBanner {}
}
