//
//  RegistrationAccountView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/20.
//

import HometeDomain
import HometeResources
import HometeUI
import SwiftUI

struct RegistrationAccountView: View {

    @LoadingState var loadingState

    @State var inputUserName = UserName()
    let authInfo: AccountAuthResult
    let authSubscriptionSyncUseCase: AuthSubscriptionSyncUseCase
    /// アカウント登録が完了したときに呼ばれる
    let onRegistered: (Account) -> Void

    var body: some View {
        VStack(spacing: .space24) {
            VStack(spacing: .space16) {
                // 入力中はキーボードで画面が狭くなるため、小さく出す
                HometteView(.wave, size: .small)
                Text("なんと呼べばいいですか？", bundle: #bundle)
                    .font(with: .headLineM)
                    .multilineTextAlignment(.center)
                Text("ニックネームでも大丈夫です。パートナーの画面にも表示され、あとから変えられます", bundle: #bundle)
                    .font(with: .body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            UserNameInputTextField(userName: $inputUserName)
            Spacer(minLength: .space24)
            Button {
                loadingState.task {
                    await tappedRegistrationButton()
                }
            } label: {
                Text("次へ", bundle: #bundle)
                    .padding(.vertical, .space8)
                    .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            .disabled(!inputUserName.canRegistration)
            Spacer()
                .frame(height: .space24)
        }
        // ほかのオンボーディングの画面と同じく、ナビゲーションバーを出さずに見出しで問いかける
        .padding(.horizontal, .space16)
        .padding(.top, .space48)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.backgroundScreen)
        .fullScreenLoadingIndicator(loadingState)
        .trackScreenView(.registrationAccount)
    }

}

// MARK: プレゼンテーションロジック

private extension RegistrationAccountView {

    func tappedRegistrationButton() async {
        do {
            let account = try await authSubscriptionSyncUseCase.syncOnRegistered(
                auth: authInfo,
                userName: inputUserName
            )
            onRegistered(account)
        } catch {
            print("occurred error: \(error)")
        }
    }

}

#Preview("RegistrationAccountView_未入力") {
    RegistrationAccountView(
        authInfo: AccountAuthResult(id: ""),
        authSubscriptionSyncUseCase: .init(
            accountStore: AccountStore(),
            cohabitantStore: CohabitantStore(),
            subscriptionStore: SubscriptionStore(),
            houseworkManager: .init(houseworkClient: .previewValue)
        ),
        onRegistered: { _ in }
    )
}

#Preview("RegistrationAccountView_入力済み") {
    RegistrationAccountView(
        authInfo: AccountAuthResult(id: "Test"),
        authSubscriptionSyncUseCase: .init(
            accountStore: AccountStore(),
            cohabitantStore: CohabitantStore(),
            subscriptionStore: SubscriptionStore(),
            houseworkManager: .init(houseworkClient: .previewValue)
        ),
        onRegistered: { _ in }
    )
}
