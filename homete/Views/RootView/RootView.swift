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
    
    @AppStorage(key: .cohabitantId) var localStorageCohabitantId = ""
    
    @Environment(AccountAuthStore.self) var accountAuthStore
    @Environment(AccountStore.self) var accountStore
    
    var body: some View {
        ZStack {
            switch accountAuthStore.state {
            case .launching:
                LaunchScreenView()
            case .loggedIn:
                AppTabView()
                    .transition(.scale)
            case .notLoggedIn:
                LoginView()
                    .transition(.scale)
            }
        }
        .animation(.spring, value: accountAuthStore.state)
        .onChange(of: accountAuthStore.state) {
            Task {
                await onChangeLaunchState(accountAuthStore.state)
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
    }
}

extension RootView {
    
    static func make() -> some View {
        DependenciesInjectLayer {
            RootView()
                .environment(AccountStore(appDependencies: $0))
                .environment(AccountAuthStore(appDependencies: $0))
                .environment(HouseworkListStore(houseworkClient: $0.houseworkClient))
        }
    }
}

// MARK: - プレゼンテーションロジック

private extension RootView {
    
    func onChangeLaunchState(_ state: LaunchState) async {
        guard case .loggedIn(let accountAuthResult) = accountAuthStore.state else { return }
        await accountStore.loadOwnAccountData(accountAuthResult, fcmToken: fcmToken)
    }
}
