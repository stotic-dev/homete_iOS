//
//  RootView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/07/26.
//

import SwiftUI

struct RootView: View {
    @Environment(\.accountStore) var accountStore
    @State var navigationPath = CustomNavigationPath(path: [RootNavigationPath]())
    
    var body: some View {
        NavigationStack(path: $navigationPath.path) {
            if accountStore?.account == nil {
                LoginView()
                    .navigationTitle("Login")
            }
            else {
                ContentView()
                    .navigationDestination(for: RootNavigationPath.self) { path in
                        path.Destination()
                    }
            }
        }
        .environment(\.rootNavigationPath, navigationPath)
    }
}

#Preview {
    RootView()
}
