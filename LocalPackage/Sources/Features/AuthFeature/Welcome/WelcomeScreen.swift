//
//  WelcomeScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// ログイン前にアプリを紹介し、匿名で始めるかApple IDでログインするかを選んでもらう画面
///
/// 「はじめる」は裏で匿名サインインし、ニックネーム登録へ進む（ADR-0051）。
/// 招待リンクを開いてから起動した人には、誰から招待が届いているかを1枚目に出す。
public struct WelcomeScreen: View {

    @Environment(AccountAuthStore.self) var accountAuthStore
    @Environment(PendingInvitationStore.self) var pendingInvitationStore
    @Environment(\.appDependencies.cohabitantInvitationClient) var cohabitantInvitationClient
    @CommonError var commonErrorContent
    @LoadingState var loadingState

    @State var navigationPath = AppNavigationPath<WelcomeRoute>()
    @State var selectedPage: WelcomePage = .record
    @State var invitationStore: WelcomeInvitationStore?

    /// サインインの後にアカウントを取得できなかったときのエラー。受け取ったら`onReceiveAccountLoadFailure`で伝える
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
        NavigationStack(path: $navigationPath.path) {
            WelcomeView(
                selectedPage: $selectedPage,
                invitation: invitationStore?.invitation ?? .none,
                onTapStart: {
                    tappedStart()
                },
                onTapExistingAccount: {
                    tappedExistingAccount()
                }
            )
            .navigationDestination(for: WelcomeRoute.self) { route in
                navigationHandler(route)
            }
        }
        // ログイン前でも招待リンクは開けるため、表示中に開かれたら読み込み直す
        .task(id: pendingInvitationStore.pendingToken) {
            await loadInvitation()
        }
        .fullScreenLoadingIndicator(loadingState)
        .commonError(content: $commonErrorContent)
        // 起動時にアカウントを取得できず説明画面になった場合も、理由が分かるよう表示時点の値を拾う
        .onChange(of: accountLoadFailure, initial: true) {
            onChangeAccountLoadFailure()
        }
        .trackScreenView(.welcome)
    }

}

// MARK: - プレゼンテーションロジック

private extension WelcomeScreen {

    @ViewBuilder
    func navigationHandler(_ route: WelcomeRoute) -> some View {
        switch route {
        case .login:
            LoginView(
                accountLoadFailure: accountLoadFailure,
                onReceiveAccountLoadFailure: onReceiveAccountLoadFailure
            )
        }
    }

    /// 「はじめる」の後にアカウントを取得できなかったら、ローディングを畳んでエラーを出す
    /// - Note: ログイン画面を開いているときは、Apple IDでのログインの失敗なので`LoginView`に任せる
    func onChangeAccountLoadFailure() {
        guard let accountLoadFailure, navigationPath.path.isEmpty else { return }
        loadingState.isLoading = false
        commonErrorContent = .init(error: accountLoadFailure)
        onReceiveAccountLoadFailure()
    }

    func loadInvitation() async {
        if invitationStore == nil {
            invitationStore = .init(cohabitantInvitationClient: cohabitantInvitationClient)
        }
        await invitationStore?.load(token: pendingInvitationStore.pendingToken)
    }

    func tappedStart() {
        Task {
            loadingState.isLoading = true
            do {
                try await accountAuthStore.startAnonymously()
                // 成功時はcurrentAuthの変化を受けてRootView側でlaunchStateが切り替わり、この画面が取り除かれる。
                // 遷移が終わる前に説明画面へ戻ったように見えないよう、LoginViewと同じくインジケータは戻さない
            } catch {
                loadingState.isLoading = false
                commonErrorContent = .init(error: error)
            }
        }
    }

    func tappedExistingAccount() {
        navigationPath.push(.login)
    }

}
