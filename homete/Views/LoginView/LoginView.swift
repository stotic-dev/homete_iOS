//
//  LoginView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import SwiftUI

struct LoginView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("ようこそ!")
                .font(.title)
            Text("サービスを利用するには、Appleアカウントでサインインする必要があります。")
                .font(.body)
            SignInUpWithAppleButton()
                .frame(height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            Spacer()
            Text("続行すると、利用規約とプライバシーポリシーに同意したことになります。")
                .font(.caption)
                .foregroundStyle(.primary2)
            Spacer()
                .frame(height: 32)
        }
        .padding(.horizontal, 16)
        .ignoresSafeArea(edges: [.bottom])
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .navigationTitle("Homete")
            .navigationBarTitleDisplayMode(.inline)
    }
}
