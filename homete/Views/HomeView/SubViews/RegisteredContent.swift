//
//  RegisteredContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/04.
//

import SwiftUI

struct RegisteredContent: View {
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Space.space24) {
                pointDashboard(monthlyPoint: 0, thanksPoint: 0)
                    .padding(.vertical, DesignSystem.Space.space16)
                // TODO: テンプレート未設定の場合のみ表示する
                promoteHouseworkTemplateBanner()
            }
            .padding(.horizontal, DesignSystem.Space.space16)
        }
    }
}

private extension RegisteredContent {
    
    func pointDashboard(monthlyPoint: Int, thanksPoint: Int) -> some View {
        HStack(spacing: DesignSystem.Space.space16) {
            VStack(spacing: DesignSystem.Space.space8) {
                Text("今月の獲得ポイント")
                    .font(with: .body)
                Text(monthlyPoint.formatted())
                    .font(with: .headLineM)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                RoundedRectangle(radius: .radius8)
                    .stroke(style: .init(lineWidth: 2, dash: [8]))
                    .foregroundStyle(.primary1)
            }
            VStack(spacing: DesignSystem.Space.space8) {
                Text("もらった感謝の数")
                    .font(with: .body)
                Text(thanksPoint.formatted())
                    .font(with: .headLineM)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                RoundedRectangle(radius: .radius8)
                    .stroke(style: .init(lineWidth: 2, dash: [8]))
                    .foregroundStyle(.primary1)
            }
        }
        .frame(minHeight: 136)
    }
    
    func promoteHouseworkTemplateBanner() -> some View {
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
            }
            Button("テンプレートを設定する") {
                // TODO: テンプレート設定画面へ遷移
            }
            .primaryButtonStyle()
        }
    }

}

#Preview {
    RegisteredContent()
}
