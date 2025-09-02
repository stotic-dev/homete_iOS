//
//  RootView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/07/26.
//

import SwiftUI

struct RootView: View {
        
    @State var navigationPath = CustomNavigationPath(path: [RootNavigationPath]())
    @State var launchState: LaunchState = .launching
    
    var accountAuthStore: AccountAuthStore
    var accountStore: AccountStore
    
    var body: some View {
        NavigationStack(path: $navigationPath.path) {
            switch launchState {
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
        .onChange(of: accountAuthStore.auth) { _, newValue in
            withAnimation {
                launchState = launchState.next(newValue)
            }
        }
        .onChange(of: launchState) {
            guard case .loggedIn(let accountAuthResult) = launchState else { return }
            Task {
                await accountStore.setInitialAccountIfNeeded(accountAuthResult)
            }
        }
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
