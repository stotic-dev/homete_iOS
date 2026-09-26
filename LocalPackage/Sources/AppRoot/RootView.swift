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

    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(AccountAuthStore.self) var accountAuthStore
    @Environment(AccountStore.self) var accountStore
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(PendingInvitationStore.self) var pendingInvitationStore
    @Environment(LaunchStateStore.self) var launchStateStore

    public var body: some View {
        ZStack {
            switch launchStateStore.launchState {
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
        .animation(.spring, value: launchStateStore.launchState)
        .onChange(of: accountAuthStore.currentAuth) {
            launchStateStore.syncAuthChange(accountAuthStore.currentAuth)
        }
        .onChange(of: accountStore.account) {
            launchStateStore.syncAccountChange(accountStore.account)
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
        .environment(\.launchStateProxy, .init { launchStateStore.update($0) })
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
            let cohabitantStore = CohabitantStore(
                cohabitantClient: $0.cohabitantClient,
                accountInfoClient: $0.accountInfoClient,
                analyticsClient: $0.analyticsClient
            )
            let pendingInvitationStore = PendingInvitationStore()
            let subscriptionStore = SubscriptionStore(
                purchaseClient: $0.purchaseClient,
                analyticsClient: $0.analyticsClient
            )
            let authSubscriptionSyncUseCase = AuthSubscriptionSyncUseCase(
                accountStore: accountStore,
                cohabitantStore: cohabitantStore,
                subscriptionStore: subscriptionStore,
                houseworkManager: $0.houseworkManager,
                houseworkClient: $0.houseworkClient,
                analyticsClient: $0.analyticsClient
            )
            let launchStateStore = LaunchStateStore(
                accountStore: accountStore,
                authSubscriptionSyncUseCase: authSubscriptionSyncUseCase,
                analyticsClient: $0.analyticsClient
            )

            RootView(authSubscriptionSyncUseCase: authSubscriptionSyncUseCase)
                .environment(accountStore)
                .environment(accountAuthStore)
                .environment(cohabitantStore)
                .environment(subscriptionStore)
                .environment(pendingInvitationStore)
                .environment(launchStateStore)
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
        launchStateStore.receive(fcmToken: fcmToken)
    }

}
