//
//  LoginView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import SwiftUI

struct LoginView: View {
    
    @Environment(AccountAuthStore.self) var accountAuthStore
    @CommonError var commonErrorContent
    @LoadingState var loadingState
    
    var body: some View {
        VStack(spacing: .space16) {
            Text(Constants.appName)
                .font(with: .headLineM)
            Text("ようこそ!")
                .font(with: .headLineL)
            Text("サービスを利用するには、Appleアカウントでサインインする必要があります。")
                .font(with: .body)
            SignInUpWithAppleButton { result in
                loadingState.task {
                    await onSignInWithApple(result)
                }
            }
            .frame(height: .space48)
            .clipShape(RoundedRectangle(cornerRadius: .space16 / 2))
            Spacer()
            Text("続行すると、利用規約とプライバシーポリシーに同意したことになります。")
                .font(with: .caption)
                .foregroundStyle(.primary2)
            Spacer()
                .frame(height: .space32)
        }
        .padding(.horizontal, .space16)
        .ignoresSafeArea(edges: [.bottom])
        .fullScreenLoadingIndicator(loadingState)
        .commonError(content: $commonErrorContent)
    }
}

private extension LoginView {
    
    func onSignInWithApple(_ result: Result<SignInWithAppleResult, any Error>) async {
        
        switch result {
        case .success(let success):
            do {
                
                try await accountAuthStore.login(success)
            }
            catch {
                
                commonErrorContent = .init(error: error)
            }
            
        case .failure(let failure):
            commonErrorContent = .init(error: failure)
        }
    }
}

#Preview {
    LoginView()
        .environment(AccountAuthStore(appDependencies: .previewValue))
}
