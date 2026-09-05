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
            let accountStore = AccountStore(accountInfoClient: $0.accountInfoClient)
            let pendingInvitationStore = PendingInvitationStore()
            let subscriptionStore = SubscriptionStore(purchaseClient: $0.purchaseClient)
            let authSubscriptionSyncUseCase = AuthSubscriptionSyncUseCase(
                accountStore: accountStore,
                subscriptionStore: subscriptionStore,
                houseworkClient: $0.houseworkClient
            )

            RootView(authSubscriptionSyncUseCase: authSubscriptionSyncUseCase)
                .environment(accountStore)
                .environment(AccountAuthStore(
                    accountAuthClient: $0.accountAuthClient,
                    analyticsClient: $0.analyticsClient,
                    signInWithAppleClient: $0.signInWithAppleClient,
                    nonceGenerationClient: $0.nonceGeneratorClient
                ))
                .environment(CohabitantStore(
                    cohabitantClient: $0.cohabitantClient,
                    accountInfoClient: $0.accountInfoClient
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

    /// Universal Linkを受け取る
    /// - Note: ログイン前にも開かれるため、ここではトークンを退避するだけにして、
    ///         ログイン後に`AppTabView`が参加画面を表示する
    func onOpenURL(_ url: URL) {
        guard let token = CohabitantInvitationLink.token(from: url) else { return }

        pendingInvitationStore.store(token)
        analyticsClient.log(.cohabitantInvitation(.linkOpened))
    }

    func onReceiveFcmToken(_ notification: NotificationCenter.Publisher.Output) {
        guard let fcmToken = notification.object as? String else { return }
        self.fcmToken = fcmToken
    }

    func onChangeAuth() async {
        guard let authResult = accountAuthStore.currentAuth.result else {
            launchState = .notLoggedIn
            await authSubscriptionSyncUseCase.syncOnSignedOut()
            return
        }

        if let account = await authSubscriptionSyncUseCase.syncOnSignedIn(authResult) {
            await updateFcmTokenIfNeeded()
            launchState = .loggedIn(context: .init(account: account))
        } else {
            launchState = .preLoggedIn(auth: authResult)
        }
    }

    func onChangeAccount() async {
        guard launchState.isLoggedIn,
              let account = accountStore.account else { return }

        await updateFcmTokenIfNeeded()
        launchState = .loggedIn(context: .init(account: account))
        // グループへの参加はアカウント更新として届くため、参加後の保持期限同期をここで拾う
        await authSubscriptionSyncUseCase.syncHouseworkRetentionIfNeeded()
    }

    func updateFcmTokenIfNeeded() async {
        guard let fcmToken else { return }
        await accountStore.updateFcmTokenIfNeeded(fcmToken)
        self.fcmToken = nil
    }

}
