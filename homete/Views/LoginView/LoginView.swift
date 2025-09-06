//
//  LoginView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import SwiftUI

struct LoginView: View {
    
    @Environment(AccountAuthStore.self) var accountAuthStore
    @State var isPresentedErrorAlert = false
    @State var domainError: DomainError?
    @State var isLoading = false
    
    var body: some View {
        ZStack {
            VStack(spacing: DesignSystem.Space.space16) {
                Text("homete")
                    .font(with: .headLineM)
                Text("ようこそ!")
                    .font(with: .headLineL)
                Text("サービスを利用するには、Appleアカウントでサインインする必要があります。")
                    .font(with: .body)
                SignInUpWithAppleButton {
                    isLoading = true
                    await onSignInWithApple($0)
                    isLoading = false
                }
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
            LoadingIndicator()
                .opacity(isLoading ? 1 : 0)
        }
        .commonError(isPresented: $isPresentedErrorAlert, error: $domainError)
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
                
                handleError(error)
            }
            
        case .failure(let failure):
            handleError(failure)
        }
    }
    
    func handleError(_ error: any Error) {
        
        domainError = .make(error)
    }
}

#Preview {
    LoginView()
        .navigationBarTitleDisplayMode(.inline)
        .environment(AccountAuthStore(appDependencies: .previewValue))
}
