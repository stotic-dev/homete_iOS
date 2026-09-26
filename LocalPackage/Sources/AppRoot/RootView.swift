//
//  RootView.swift
//

import AuthFeature
import HometeDomain
import HometeUI
import SwiftUI

public struct RootView: View {

    let authSubscriptionSyncUseCase: AuthSubscriptionSyncUseCase

    @State var theme = Theme()
    @State var fcmToken: String?
    @State var launchState = LaunchState.launching

    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(AccountAuthStore.self) var accountAuthStore
    @Environment(AccountStore.self) var accountStore
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(PendingInvitationStore.self) var pendingInvitationStore

    public var body: some View {
        ZStack {
            switch launchState {
            case .launching:
                LaunchScreenView()
            case let .preLoggedIn(auth):
                OnboardingFlowView(authInfo: auth, authSubscriptionSyncUseCase: authSubscriptionSyncUseCase)
                    .transition(.asymmetric(
                        insertion: .push(from: .leading),
                        removal: .opacity
                    ))
            case let .loggedIn(context):
                AppTabView()
                    .environment(\.loginContext, context)
                    .transition(.scale)
            case .notLoggedIn:
                LoginView()
            }
        }
        .animation(.spring, value: launchState)
        .onChange(of: accountAuthStore.currentAuth) {
            Task {
                await onChangeAuth()
            }
        }
        .onChange(of: accountStore.account) {
            Task {
                await onChangeAccount()
            }
        }
        .onChange(of: subscriptionStore.isPremium) {
            Task {
                await authSubscriptionSyncUseCase.syncPremiumStateIfNeeded()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didReceiveFcmToken)) { notification in
            onReceiveFcmToken(notification)
        }
        .onOpenURL { url in
            onOpenURL(url)
        }
        .apply(theme: theme)
        .environment(\.launchStateProxy, .init(launchState: $launchState))
    }

}

public extension RootView {

    static func make(dependencies: AppDependencies) -> some View {
        DependenciesInjectLayer {
            let accountAuthStore = AccountAuthStore(
                accountAuthClient: $0.accountAuthClient,
                analyticsClient: $0.analyticsClient,
                signInWithAppleClient: $0.signInWithAppleClient,
                nonceGenerationClient: $0.nonceGeneratorClient
            )
            let accountStore = AccountStore(accountInfoClient: $0.accountInfoClient)
            let pendingInvitationStore = PendingInvitationStore()
            let subscriptionStore = SubscriptionStore(
                purchaseClient: $0.purchaseClient,
                analyticsClient: $0.analyticsClient
            )
            let authSubscriptionSyncUseCase = AuthSubscriptionSyncUseCase(
                accountAuthStore: accountAuthStore,
                accountStore: accountStore,
                subscriptionStore: subscriptionStore,
                houseworkClient: $0.houseworkClient,
                analyticsClient: $0.analyticsClient
            )

            RootView(authSubscriptionSyncUseCase: authSubscriptionSyncUseCase)
                .environment(accountStore)
                .environment(accountAuthStore)
                .environment(CohabitantStore(
                    cohabitantClient: $0.cohabitantClient,
                    accountInfoClient: $0.accountInfoClient,
                    analyticsClient: $0.analyticsClient
                ))
                .environment(subscriptionStore)
                .environment(pendingInvitationStore)
                .task {
                    await subscriptionStore.observeEntitlementUpdates()
                }
                .routeResolverInjection()
                .adComponentResolverInjection()
        }
        .environment(\.appDependencies, dependencies)
    }

}

// MARK: - プレゼンテーションロジック

private extension RootView {

    /// 招待リンク（Universal Link / カスタムURLスキーム）を受け取る
    /// - Note: ログイン前にも開かれるため、ここではトークンを退避するだけにして、
    ///         ログイン後に`AppTabView`が参加画面を表示する
    func onOpenURL(_ url: URL) {
        guard let link = CohabitantInvitationLink.parse(url) else { return }

        pendingInvitationStore.store(link.token)
        analyticsClient.log(.cohabitantInvitation(.linkOpened(source: link.source)))
    }

    func onReceiveFcmToken(_ notification: NotificationCenter.Publisher.Output) {
        guard let fcmToken = notification.object as? String else { return }
        self.fcmToken = fcmToken
    }

    func onChangeAuth() async {
        let handlingAuth = accountAuthStore.currentAuth

        guard let authResult = handlingAuth.result else {
            launchState = .notLoggedIn
            await authSubscriptionSyncUseCase.syncOnSignedOut()
            return
        }

        guard let account = await authSubscriptionSyncUseCase.syncOnSignedIn(authResult) else {
            guard isHandling(handlingAuth) else { return }
            launchState = .preLoggedIn(auth: authResult)
            return
        }

        await updateFcmTokenIfNeeded()
        guard isHandling(handlingAuth) else { return }
        let context = LoginContext(account: account)
        analyticsClient.setUserProperty(.hasCohabitant(context.hasCohabitant))
        launchState = .loggedIn(context: context)
    }

    func onChangeAccount() async {
        guard launchState.isLoggedIn,
              let account = accountStore.account else { return }
        let handlingAuth = accountAuthStore.currentAuth

        await updateFcmTokenIfNeeded()
        guard isHandling(handlingAuth) else { return }
        let context = LoginContext(account: account)
        analyticsClient.setUserProperty(.hasCohabitant(context.hasCohabitant))
        launchState = .loggedIn(context: context)
        // グループへの参加はアカウント更新として届くため、参加後の保持期限同期をここで拾う
        await authSubscriptionSyncUseCase.syncHouseworkRetentionIfNeeded()
    }

    /// 処理を始めたときの認証状態が、いまも維持されているかどうか
    /// - Note: トークン失効による自動サインアウトはFirebase Auth側の判断で非同期に起きるため、
    ///         `launchState`の更新はawaitを挟んだ時点で古い判断になっている可能性がある。
    ///         古い認証情報のまま画面を進めると、サインアウト済みのユーザーIDでFirestoreを読み書きしてしまう。
    ///         新しい認証状態の通知を処理する側が改めて画面を切り替えるため、ここでは何もしないのが正しい
    func isHandling(_ auth: AccountAuthInfo) -> Bool {
        accountAuthStore.currentAuth == auth
    }

    func updateFcmTokenIfNeeded() async {
        guard let fcmToken else { return }
        await accountStore.updateFcmTokenIfNeeded(fcmToken)
        self.fcmToken = nil
    }

}
