//
//  RootView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/07/26.
//

import SwiftUI

struct RootView: View {
        
    @State var navigationPath = CustomNavigationPath(path: [RootNavigationPath]())
    @State var theme = Theme()
    
    var accountAuthStore: AccountAuthStore
    var accountStore: AccountStore
    
    var body: some View {
        NavigationStack(path: $navigationPath.path) {
            switch accountAuthStore.state {
            case .launching:
                LaunchScreenView()
            case .loggedIn:
                HomeView()
                    .navigationDestination(for: RootNavigationPath.self) { path in
                        path.destination()
                    }
                    .transition(.scale)
            case .notLoggedIn:
                LoginView()
                    .transition(.scale)
            }
        }
        .animation(.spring, value: accountAuthStore.state)
        .onChange(of: accountAuthStore.state) {
            guard case .loggedIn(let accountAuthResult) = accountAuthStore.state else { return }
            Task {
                await accountStore.setInitialAccountIfNeeded(accountAuthResult)
            }
        }
        .apply(theme: theme)
        .environment(\.rootNavigationPath, navigationPath)
        .environment(accountStore)
        .environment(accountAuthStore)
    }
}

#Preview {
    RootView(
        accountAuthStore: .init(appDependencies: .previewValue),
        accountStore: .init(appDependencies: .previewValue)
    )
}
