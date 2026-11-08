//
//  RegistrationAccountScreen.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/20.
//

import AuthFeatureUI
import HometeDomain
import HometeUI
import SwiftUI

struct RegistrationAccountScreen: View {

    @LoadingState var loadingState

    let authInfo: AccountAuthResult
    let authSubscriptionSyncUseCase: AuthSubscriptionSyncUseCase
    /// アカウント登録が完了したときに呼ばれる
    let onRegistered: (Account) -> Void

    var body: some View {
        RegistrationAccountView { userName in
            loadingState.task {
                await tappedRegistrationButton(userName: userName)
            }
        }
        .fullScreenLoadingIndicator(loadingState)
        .trackScreenView(.registrationAccount)
    }

}

// MARK: プレゼンテーションロジック

private extension RegistrationAccountScreen {

    func tappedRegistrationButton(userName: UserName) async {
        do {
            let account = try await authSubscriptionSyncUseCase.syncOnRegistered(
                auth: authInfo,
                userName: userName
            )
            onRegistered(account)
        } catch {
            print("occurred error: \(error)")
        }
    }

}
