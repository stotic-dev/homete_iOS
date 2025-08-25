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
    @State var shouldShowHomeView = false
    
    var accountAuthStore: AccountAuthStore
    var accountStore: AccountStore
    
    var body: some View {
        NavigationStack(path: $navigationPath.path) {
            if shouldShowHomeView {
                HomeView()
                    .navigationDestination(for: RootNavigationPath.self) { path in
                        path.destination()
                    }
                    .task {
                        guard let auth = accountAuthStore.auth else { return }
                        await accountStore.setAccountOnLogin(auth)
                    }
                    .animation(.default, value: accountAuthStore.isLogin)
                    .transition(.scale)
            }
            else {
                LoginView()
                    .animation(.default, value: accountAuthStore.isLogin)
                    .transition(.scale)
            }
        }
        .onChange(of: accountAuthStore.isLogin) { _, newValue in
            withAnimation {
                shouldShowHomeView = newValue
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
