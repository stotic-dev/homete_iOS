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
                todayHouseworkListContent()
                timelineContent()
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
                    .multilineTextAlignment(.center)
            }
            Button("テンプレートを設定する") {
                // TODO: テンプレート設定画面へ遷移
            }
            .primaryButtonStyle()
        }
    }

    func todayHouseworkListContent() -> some View {
        VStack(spacing: DesignSystem.Space.space24) {
            Text("今日の家事リスト")
                .font(with: .headLineM)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: .zero) {
                Text("家事がありません")
                    .font(with: .headLineS)
                Spacer()
                    .frame(height: DesignSystem.Space.space8)
                Text("今日の家事を確認して、家事リストを設定しましょう！")
                    .font(with: .body)
                    .multilineTextAlignment(.center)
                Spacer()
                    .frame(height: DesignSystem.Space.space24)
                Button("家事を設定する") {
                    // TODO: 家事設定画面へ遷移
                }
                .primaryButtonStyle()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Space.space56)
            .overlay {
                RoundedRectangle(radius: .radius8)
                    .stroke(style: .init(lineWidth: 2, dash: [8]))
                    .foregroundStyle(.primary1)
            }
        }
    }
    
    func timelineContent() -> some View {
        VStack(spacing: DesignSystem.Space.space24) {
            Text("タイムライン")
                .font(with: .headLineM)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: .zero) {
                Text("まだアクティビティがありません")
                    .font(with: .headLineS)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Space.space56)
            .overlay {
                RoundedRectangle(radius: .radius8)
                    .stroke(style: .init(lineWidth: 2, dash: [8]))
                    .foregroundStyle(.primary1)
            }
        }
    }
}

#Preview {
    RegisteredContent()
}
