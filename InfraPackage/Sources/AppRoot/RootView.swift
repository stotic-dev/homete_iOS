//
//  RootView.swift
//

import AuthFeature
import HometeDomain
import HometeUI
import SwiftUI

public struct RootView: View {

    let authSubscriptionSyncUseCase: AuthSubscriptionSyncUseCase
    let remoteConfigSyncUseCase: RemoteConfigSyncUseCase

    @State var theme = Theme()
    @State var hasEnteredBackground = false

    @Environment(\.appDependencies.analyticsClient) var analyticsClient
    @Environment(\.scenePhase) var scenePhase
    @Environment(AccountAuthStore.self) var accountAuthStore
    @Environment(AccountStore.self) var accountStore
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(PendingInvitationStore.self) var pendingInvitationStore
    @Environment(PendingRouteStore.self) var pendingRouteStore
    @Environment(LaunchStateStore.self) var launchStateStore
    @Environment(AdvertisementStore.self) var advertisementStore
    @Environment(ForceUpdateStore.self) var forceUpdateStore
    @Environment(MaintenanceStore.self) var maintenanceStore

    public var body: some View {
        ZStack {
            // 他の画面に進めないよう、ログイン状態に関係なく画面ごと差し替える。
            // 差し替えると表示中のシートなども閉じられるため、案内が別の画面の裏に隠れない
            switch appAvailability {
            case .underMaintenance:
                MaintenanceView()
                    .trackScreenView(.maintenance)
            case .updateRequired:
                ForceUpdateView()
                    .trackScreenView(.forceUpdate)
            case .available:
                switch launchStateStore.launchState {
                case .launching:
                    LaunchScreenView()
                        .trackScreenView(.launch)
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
                case .accountLinkRequired:
                    // 匿名のままグループに参加している。連携を終えるまでホームに入れないため、閉じる導線を出さない
                    AccountLinkScreen(entry: .required)
                case .notLoggedIn:
                    // アプリの価値が伝わる前にログインで離脱しないよう、先に説明画面を出す。
                    // すでにアカウントを持っている人は、説明画面からApple IDでのログインへ進む
                    WelcomeScreen(
                        accountLoadFailure: launchStateStore.accountLoadFailure,
                        onReceiveAccountLoadFailure: { launchStateStore.clearAccountLoadFailure() }
                    )
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
        .onChange(of: launchStateStore.launchState) {
            onChangeLaunchState()
        }
        .onChange(of: maintenanceStore.isUnderMaintenance) {
            discardPendingEntriesIfUnderMaintenance()
        }
        .onChange(of: pendingRouteStore.pendingRoute) {
            discardPendingEntriesIfUnderMaintenance()
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
        .environment(\.isAdsEnabled, advertisementStore.isAdsEnabled)
    }

}

public extension RootView {

    /// - Parameter pendingRouteStore: タップされた通知から開く画面。通知のタップを受け取る`AppDelegate`と共有する
    static func make(
        dependencies: AppDependencies,
        pendingRouteStore: PendingRouteStore
    ) -> some View {
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
            let sentInvitationStore = SentInvitationStore(sentInvitationClient: $0.sentInvitationClient)
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
                analyticsClient: $0.analyticsClient,
                sentInvitationStore: sentInvitationStore
            )
            let advertisementStore = AdvertisementStore(remoteConfigClient: $0.remoteConfigClient)
            let forceUpdateStore = ForceUpdateStore(
                remoteConfigClient: $0.remoteConfigClient,
                currentAppVersion: Bundle.main
                    .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
            )
            let maintenanceStore = MaintenanceStore(
                remoteConfigClient: $0.remoteConfigClient,
                maintenanceStateClient: $0.maintenanceStateClient
            )
            let remoteConfigSyncUseCase = RemoteConfigSyncUseCase(
                remoteConfigClient: $0.remoteConfigClient,
                advertisementStore: advertisementStore,
                forceUpdateStore: forceUpdateStore,
                maintenanceStore: maintenanceStore
            )
            let registrationTutorialStore = RegistrationTutorialStore(
                stateClient: $0.registrationTutorialStateClient,
                analyticsClient: $0.analyticsClient
            )
            let launchStateStore = LaunchStateStore(
                accountStore: accountStore,
                authSubscriptionSyncUseCase: authSubscriptionSyncUseCase,
                analyticsClient: $0.analyticsClient,
                accountAuthClient: $0.accountAuthClient
            )

            RootView(
                authSubscriptionSyncUseCase: authSubscriptionSyncUseCase,
                remoteConfigSyncUseCase: remoteConfigSyncUseCase
            )
            .environment(accountStore)
            .environment(accountAuthStore)
            .environment(cohabitantStore)
            .environment(subscriptionStore)
            .environment(pendingInvitationStore)
            .environment(sentInvitationStore)
            .environment(pendingRouteStore)
            .environment(launchStateStore)
            .environment(advertisementStore)
            .environment(forceUpdateStore)
            .environment(maintenanceStore)
            .environment(registrationTutorialStore)
            .task {
                await subscriptionStore.observeEntitlementUpdates()
            }
            .task {
                // 起動処理とは並行に走らせ、完了を待たない
                await remoteConfigSyncUseCase.setupOnLaunch()
            }
            .task {
                await remoteConfigSyncUseCase.observeConfigUpdates()
            }
            .routeResolverInjection()
            .adComponentResolverInjection()
        }
        .environment(\.appDependencies, dependencies)
    }

}

// MARK: - プレゼンテーションロジック

private extension RootView {

    var appAvailability: AppAvailability {
        .init(
            isUnderMaintenance: maintenanceStore.isUnderMaintenance,
            isForceUpdateRequired: forceUpdateStore.isForceUpdateRequired
        )
    }

    /// 招待リンク（Universal Link / カスタムURLスキーム）を受け取る
    /// - Note: ログイン前にも開かれるため、ここではトークンを退避するだけにして、
    ///         ログイン後に`AppTabView`が参加画面を表示する。メンテナンス中に開かれたリンクは、
    ///         終わった後に急に参加画面が開かないよう受け取らない
    func onOpenURL(_ url: URL) {
        guard !maintenanceStore.isUnderMaintenance,
              let link = CohabitantInvitationLink.parse(url) else { return }

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
                await remoteConfigSyncUseCase.refresh()
            }
        default:
            break
        }
    }

    /// ログアウトしたら、前のアカウントで受け取った通知から画面を開かないよう破棄する
    /// - Note: 起動時はログイン済みなら`launching`から直接`loggedIn`になるため、起動のきっかけになった通知は消さない
    func onChangeLaunchState() {
        guard case .notLoggedIn = launchStateStore.launchState else { return }
        pendingRouteStore.clear()
    }

    /// メンテナンス中は、通知のタップ・App Intent・招待リンクから開く画面を破棄する
    /// - Note: メンテナンスが終わった後に、ユーザーが覚えていない画面が急に開かないようにする。
    ///         メンテナンスに入った時点でまだ使われていないもの（起動のきっかけになった通知やリンクを含む）も破棄する
    func discardPendingEntriesIfUnderMaintenance() {
        guard maintenanceStore.isUnderMaintenance else { return }
        pendingRouteStore.clear()
        pendingInvitationStore.clear()
    }

    func onReceiveFcmToken(_ notification: NotificationCenter.Publisher.Output) {
        guard let fcmToken = notification.object as? String else { return }
        launchStateStore.receive(fcmToken: fcmToken)
    }

}
