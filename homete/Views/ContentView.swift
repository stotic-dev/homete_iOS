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
    @Environment(\.appDependencies.accountRepository) var accountRepository
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world! \(rootNavigationPath.path.count)")
            Button("Debug") {
                rootNavigationPath.showContent()
            }
            Button("LogOut") {
                do {
                    try accountRepository.signOut()
                }
                catch {
                    print("error: \(error)")
                }
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
