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
                ContentView()
                    .navigationDestination(for: RootNavigationPath.self) { path in
                        path.Destination()
                    }
                    .environment(accountStore)
                    .task {
                        await accountStore.setAccountOnLogin(auth)
                    }
            }
            else {
                LoginView(accountAuthStore: accountAuthStore)
                    .navigationTitle("Homete")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .environment(\.rootNavigationPath, navigationPath)
    }
}

#Preview {
    RootView(
        accountAuthStore: .init(appDependencies: .previewValue),
        accountStore: .init(appDependencies: .previewValue)
    )
}
