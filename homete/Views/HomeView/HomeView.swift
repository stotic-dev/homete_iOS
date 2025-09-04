//
//  HomeView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

struct HomeView: View {
    
    @Environment(\.rootNavigationPath) var rootNavigationPath
        
    var body: some View {
        NotRegisteredContent()
            .navigationTitle("homete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationBarButton(label: .settings) {
                        rootNavigationPath.showSettingView()
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
