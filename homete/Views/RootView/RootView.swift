//
//  RootView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/07/26.
//

import FirebaseMessaging
import SwiftUI

struct RootView: View {
        
    @State var theme = Theme()
    @State var fcmToken: String?
    @State var launchState = LaunchState.launching
    
    @AppStorage(key: .cohabitantId) var localStorageCohabitantId = ""
    
    @Environment(AccountAuthStore.self) var accountAuthStore
    @Environment(AccountStore.self) var accountStore
    
    var body: some View {
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
                await onChangeAuth(accountAuthStore.currentAuth)
            }
        }
        .task(id: accountStore.account) {
            guard let fcmToken else { return }
            await accountStore.updateFcmTokenIfNeeded(fcmToken)
        }
        .onReceive(NotificationCenter.default.publisher(for: .didReceiveFcmToken)) { notification in
            guard let fcmToken = notification.object as? String else { return }
            self.fcmToken = fcmToken
            Task {
                await accountStore.updateFcmTokenIfNeeded(fcmToken)
            }
        }
        .apply(theme: theme)
        .environment(\.cohabitantId, localStorageCohabitantId)
        .environment(\.launchStateProxy, .init(launchState: $launchState))
    }
}

extension RootView {
    
    static func make() -> some View {
        DependenciesInjectLayer {
            RootView()
                .environment(AccountStore(appDependencies: $0))
                .environment(AccountAuthStore(appDependencies: $0))
                .environment(HouseworkListStore(
                    houseworkClient: $0.houseworkClient,
                    cohabitantPushNotificationClient: $0.cohabitantPushNotificationClient
                ))
        }
    }
}

// MARK: - プレゼンテーションロジック

private extension RootView {
    
    func onChangeAuth(_ auth: AccountAuthResult?) async {
        guard let auth else {
            launchState = .notLoggedIn
            return
        }
        
        if await accountStore.load(auth) {
            launchState = .loggedIn(context: .init(account: accountStore.account))
        } else {
            launchState = .preLoggedIn(auth: auth)
        }
    }
}
