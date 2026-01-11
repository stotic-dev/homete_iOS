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
    @LoadingState var loadingState
    
    @State var inputUserName = UserName()
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
                Spacer(minLength: .space24)
                Button {
                    loadingState.task {
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
        .fullScreenLoadingIndicator(loadingState)
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
        .fixedSize(horizontal: false, vertical: true)
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
    }
}

#Preview("RegistrationAccountView_未入力") {
    RegistrationAccountView(authInfo: .init(id: ""))
        .environment(AccountStore(appDependencies: .previewValue))
}

#Preview("RegistrationAccountView_入力済み") {
    RegistrationAccountView(
        loadingState: .init(store: .init(isLoading: true)),
        authInfo: .init(id: "Test")
    )
    .environment(AccountStore(appDependencies: .previewValue))
}
