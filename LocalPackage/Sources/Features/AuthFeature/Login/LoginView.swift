//
//  LoginView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import HometeDomain
import HometeResources
import HometeUI
import SwiftUI

public struct LoginView: View {

    @Environment(AccountAuthStore.self) var accountAuthStore
    @CommonError var commonErrorContent
    @LoadingState var loadingState

    public init() {}

    public var body: some View {
        VStack(spacing: .space16) {
            Text(Constants.appName)
                .font(with: .headLineM)
            Text("ようこそ!")
                .font(with: .headLineL)
            Text("サービスを利用するには、Appleアカウントでサインインする必要があります。")
                .font(with: .body)
            SignInUpWithAppleButton { result in
                await onSignInWithApple(result)
            }
            .frame(height: .space48)
            .clipShape(RoundedRectangle(cornerRadius: .space16 / 2))
            Spacer()
            // swiftlint:disable:next line_length
            Text(
                "続行すると、[利用規約](https://stotic-dev.github.io/homete_iOS/terms.html)と[プライバシーポリシー](https://stotic-dev.github.io/homete_iOS/privacy.html)に同意したことになります。"
            )
            .font(with: .caption)
            .foregroundStyle(.primary2)
            .tint(.primary2)
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
        case let .success(success):
            loadingState.isLoading = true
            do {
                try await accountAuthStore.login(success)
                // 成功時はcurrentAuthの変化を受けてRootView側でlaunchStateが切り替わり、
                // LoginView自体が画面から取り除かれる。ここでisLoadingをfalseに戻すと、
                // 実際の遷移（Firestoreからのアカウント取得等）が終わるより先にインジケータが消え、
                // 遷移完了までの間ログイン画面に戻ったように見えてしまうため、意図的に戻さない。
            } catch {
                loadingState.isLoading = false
                commonErrorContent = .init(error: error)
            }

        case let .failure(failure):
            commonErrorContent = .init(error: failure)
        }
    }

}

#Preview {
    LoginView()
        .environment(AccountAuthStore())
}
