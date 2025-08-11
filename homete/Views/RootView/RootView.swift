//
//  RootView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/07/26.
//

import SwiftUI

struct RootView: View {
    @Environment(\.appDependencies) var appDependencies
    @State var navigationPath = CustomNavigationPath(path: [RootNavigationPath]())
    
    var accountAuthStore: AccountAuthStore
    var accountStore: AccountStore
    
    var body: some View {
        NavigationStack(path: $navigationPath.path) {
            if accountAuthStore.isLogin,
               let auth = accountAuthStore.auth {
                HomeView()
                    .navigationDestination(for: RootNavigationPath.self) { path in
                        path.destination()
                    }
                    .environment(accountStore)
                    .task {
                        await accountStore.setAccountOnLogin(auth)
                    }
            }
            else {
                LoginView()
            }
        }
        .environment(\.rootNavigationPath, navigationPath)
        .environment(accountAuthStore)
    }
}

#Preview {
    RootView(
        accountAuthStore: .init(appDependencies: .previewValue),
        accountStore: .init(appDependencies: .previewValue)
    )
}
