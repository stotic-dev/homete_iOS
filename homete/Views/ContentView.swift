//
//  ContentView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/04/22.
//

import AuthenticationServices
import SwiftUI

struct ContentView: View {
    
    @Environment(\.rootNavigationPath) var rootNavigationPath
    @Environment(AccountStore.self) var accountStore
    
    var body: some View {
        ZStack {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Name: \(accountStore.account.displayName): \(rootNavigationPath.path.count)")
                Button("Debug") {
                    rootNavigationPath.showContent()
                }
                Button("LogOut") {
                    accountStore.logOut()
                }
                Spacer()
            }
            .padding()
            LoadingIndicator()
                .opacity(accountStore.account == .empty ? 1 : 0)
        }
    }
}

#Preview {
    ContentView()
}
