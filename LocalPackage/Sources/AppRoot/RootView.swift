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
    @State var hasEnteredBackground = false

    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(\.scenePhase) var scenePhase
    @Environment(AccountAuthStore.self) var accountAuthStore
    @Environment(AccountStore.self) var accountStore
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(PendingInvitationStore.self) var pendingInvitationStore
    @Environment(LaunchStateStore.self) var launchStateStore
    @Environment(RemoteConfigStore.self) var remoteConfigStore

    public var body: some View {
        ZStack {
            if let forceUpdateRequirement = remoteConfigStore.forceUpdateRequirement {
                // 他の画面に進めないよう、ログイン状態に関係なく画面ごと差し替える。
                // 差し替えると表示中のシートなども閉じられるため、案内が別の画面の裏に隠れない
                ForceUpdateView(message: forceUpdateRequirement.message)
            } else {
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
        .onChange(of: scenePhase) {
            onChangeScenePhase()
        }
        .apply(theme: theme)
        .environment(\.launchStateProxy, .init { launchStateStore.update($0) })
        .environment(\.isAdsEnabled, remoteConfigStore.isAdsEnabled)
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
            let remoteConfigStore = RemoteConfigStore(
                remoteConfigClient: $0.remoteConfigClient,
                currentAppVersion: Bundle.main
                    .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
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
                .environment(remoteConfigStore)
                .task {
                    await subscriptionStore.observeEntitlementUpdates()
                }
                .task {
                    // 起動処理とは並行に走らせ、完了を待たない
                    await remoteConfigStore.setupOnLaunch()
                }
                .task {
                    await remoteConfigStore.observeConfigUpdates()
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

    /// バックグラウンドから復帰したときに、Remote Configの最新の値を取得する
    /// - Note: 起動直後のinactive → activeで`setupOnLaunch`と二重に取得しないよう、一度backgroundに入った後の復帰に限る。
    ///         復帰はbackground → inactive → activeと遷移するため、直前のフェーズではなくフラグで判定する
    func onChangeScenePhase() {
        switch scenePhase {
        case .background:
            hasEnteredBackground = true
        case .active where hasEnteredBackground:
            hasEnteredBackground = false
            Task {
                await remoteConfigStore.refresh()
            }
        default:
            break
        }
    }

    func onReceiveFcmToken(_ notification: NotificationCenter.Publisher.Output) {
        guard let fcmToken = notification.object as? String else { return }
        launchStateStore.receive(fcmToken: fcmToken)
    }

}
