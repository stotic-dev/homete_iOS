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
                .environment(CohabitantStore(appDependencies: $0))
        }
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
