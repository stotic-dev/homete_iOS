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

    /// サインイン後にアカウントを取得できず、ログイン画面へ戻されたときのエラー
    let accountLoadFailure: DomainError?
    /// `accountLoadFailure`を表示に反映したことを伝える
    let onReceiveAccountLoadFailure: () -> Void

    public init(
        accountLoadFailure: DomainError? = nil,
        onReceiveAccountLoadFailure: @escaping () -> Void = {}
    ) {
        self.accountLoadFailure = accountLoadFailure
        self.onReceiveAccountLoadFailure = onReceiveAccountLoadFailure
    }

    public var body: some View {
        VStack(spacing: .space16) {
            HometteView(.wave, size: .large)
            Text("\(Constants.appName)へようこそ", bundle: #bundle)
                .font(with: .headLineL)
            Text("Appleアカウントで、すぐに始められます", bundle: #bundle)
                .font(with: .body)
            SignInUpWithAppleButton { result in
                await onSignInWithApple(result)
            }
            .frame(height: .space48)
            .cornerRadius(.radius12)
            Spacer()
            // swiftlint:disable:next line_length
            Text(
                "続行すると、[利用規約](https://stotic-dev.github.io/homete_iOS/terms.html)と[プライバシーポリシー](https://stotic-dev.github.io/homete_iOS/privacy.html)に同意したことになります。",
                bundle: #bundle
            )
            .font(with: .caption)
            .foregroundStyle(.textSecondary)
            .tint(.textAccent)
            Spacer()
                .frame(height: .space32)
        }
        .padding(.horizontal, .space16)
        .ignoresSafeArea(edges: [.bottom])
        .fullScreenLoadingIndicator(loadingState)
        .commonError(content: $commonErrorContent)
        // 起動時にアカウントを取得できずログイン画面になった場合も、理由が分かるよう表示時点の値を拾う
        .onChange(of: accountLoadFailure, initial: true) {
            onChangeAccountLoadFailure()
        }
        .trackScreenView(.login)
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
                // アカウントの取得に失敗してログイン画面のまま戻ってきた場合は`onChangeAccountLoadFailure`で戻す。
            } catch {
                loadingState.isLoading = false
                commonErrorContent = .init(error: error)
            }

        case let .failure(failure):
            commonErrorContent = .init(error: failure)
        }
    }

    /// サインインの後にアカウントを取得できなかったら、ローディングを畳んでエラーを出す
    ///
    /// 失敗するとログイン画面のまま戻ってくるため、画面の切り替えではローディングが消えない
    func onChangeAccountLoadFailure() {
        guard let accountLoadFailure else { return }
        loadingState.isLoading = false
        commonErrorContent = .init(error: accountLoadFailure)
        onReceiveAccountLoadFailure()
    }

}

#Preview {
    LoginView()
        .environment(AccountAuthStore())
}
