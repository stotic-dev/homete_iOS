//
//  ContentView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/04/22.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.rootNavigationPath) var rootNavigationPath
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world! \(rootNavigationPath.path.count)")
            Button("Debug") {
                rootNavigationPath.showContent()
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
