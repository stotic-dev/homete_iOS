//
//  RootView.swift
//

import AuthFeature
import HometeDomain
import HometeUI
import SwiftUI

public struct RootView: View {

    @State var theme = Theme()
    @State var fcmToken: String?
    @State var launchState = LaunchState.launching

    @Environment(AccountAuthStore.self) var accountAuthStore
    @Environment(AccountStore.self) var accountStore

    public var body: some View {
        ZStack {
            switch launchState {
            case .launching:
                LaunchScreenView()
            case .preLoggedIn(let auth):
                RegistrationAccountView(authInfo: auth)
                    .transition(.asymmetric(
                        insertion: .push(from: .leading),
                        removal: .opacity
                    ))
            case .loggedIn(let context):
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
        .onReceive(NotificationCenter.default.publisher(for: .didReceiveFcmToken)) { notification in
            onReceiveFcmToken(notification)
        }
        .apply(theme: theme)
        .environment(\.launchStateProxy, .init(launchState: $launchState))
    }
}

public extension RootView {

    static func make(dependencies: AppDependencies) -> some View {
        DependenciesInjectLayer {
            RootView()
                .environment(AccountStore(accountInfoClient: $0.accountInfoClient))
                .environment(AccountAuthStore(
                    accountAuthClient: $0.accountAuthClient,
                    analyticsClient: $0.analyticsClient,
                    signInWithAppleClient: $0.signInWithAppleClient,
                    nonceGenerationClient: $0.nonceGeneratorClient
                ))
                .environment(HouseworkListStore(
                    houseworkClient: $0.houseworkClient,
                    cohabitantPushNotificationClient: $0.cohabitantPushNotificationClient
                ))
                .environment(CohabitantStore(
                    cohabitantClient: $0.cohabitantClient,
                    accountInfoClient: $0.accountInfoClient
                ))
                .routeResolverInjection()
        }
        .environment(\.appDependencies, dependencies)
    }
}

// MARK: - プレゼンテーションロジック

private extension RootView {

    func onReceiveFcmToken(_ notification: NotificationCenter.Publisher.Output) {

        guard let fcmToken = notification.object as? String else { return }
        self.fcmToken = fcmToken
    }

    func onChangeAuth() async {
        guard let authResult = accountAuthStore.currentAuth.result else {
            launchState = .notLoggedIn
            return
        }

        if let account = await accountStore.load(authResult) {

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
    }

    func updateFcmTokenIfNeeded() async {

        guard let fcmToken else { return }
        await accountStore.updateFcmTokenIfNeeded(fcmToken)
        self.fcmToken = nil
    }
}
