//
//  LoginView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import SwiftUI

struct LoginView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Space.space16) {
            Text("ようこそ!")
                .font(with: .headLineL)
            Text("サービスを利用するには、Appleアカウントでサインインする必要があります。")
                .font(with: .body)
            SignInUpWithAppleButton()
                .frame(height: DesignSystem.Space.space48)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Space.space16 / 2))
            Spacer()
            Text("続行すると、利用規約とプライバシーポリシーに同意したことになります。")
                .font(with: .caption)
                .foregroundStyle(.primary2)
            Spacer()
                .frame(height: DesignSystem.Space.space32)
        }
        .padding(.horizontal, DesignSystem.Space.space16)
        .ignoresSafeArea(edges: [.bottom])
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .navigationTitle("Homete")
            .navigationBarTitleDisplayMode(.inline)
    }
    .environment(\.appDependencies, .previewValue)
}
