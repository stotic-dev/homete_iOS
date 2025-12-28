//
//  RegistrationAccountView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/20.
//

import SwiftUI

struct RegistrationAccountView: View {
    @Environment(AccountStore.self) var accountStore
    @Environment(\.launchStateProxy) var launchStateProxy
    
    @State var inputUserName = UserName()
    @State var isLoading = false
    let authInfo: AccountAuthResult
    
    var body: some View {
        AppNavigationStackView { _ in
            VStack(spacing: .space24) {
                VStack(spacing: .space16) {
                    Text("はじめまして！")
                        .font(with: .headLineM)
                    Text("まずはあなたのニックネームを教えてください")
                        .font(with: .body)
                        .foregroundStyle(.primary2)
                }
                VStack(spacing: .space8) {
                    Text("ユーザー名")
                        .font(with: .headLineS)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    UserNameInputTextField(userName: $inputUserName)
                    userNameCautionMessage()
                }
                Spacer()
                Button {
                    Task {
                        isLoading = true
                        await tappedRegistrationButton()
                    }
                } label: {
                    Text("登録")
                        .padding(.vertical, .space8)
                        .frame(maxWidth: .infinity)
                }
                .subPrimaryButtonStyle()
                .disabled(!inputUserName.canRegistration)
                Spacer()
                    .frame(height: .space24)
            }
            .padding(.horizontal, .space16)
            .navigationTitle("アカウント登録")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenLoadingIndicator(isLoading)
    }
}

private extension RegistrationAccountView {
    func userNameCautionMessage() -> some View {
        HStack(alignment: .top, spacing: .space8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.alert)
            Text("この名前はパートナーの画面でも表示されます。\n後からいつでも変更可能です。")
                .font(with: .caption)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: プレゼンテーションロジック

private extension RegistrationAccountView {
    
    func tappedRegistrationButton() async {
        
        do {
            
            let account = try await accountStore.registerAccount(auth: authInfo, userName: inputUserName)
            launchStateProxy(.loggedIn(context: .init(account: account)))
        } catch {
            
            print("occurred error: \(error)")
        }
        
        isLoading = false
    }
}

#Preview {
    RegistrationAccountView(authInfo: .init(id: ""))
        .environment(AccountStore(appDependencies: .previewValue))
}
