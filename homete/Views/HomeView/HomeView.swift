//
//  HomeView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

struct HomeView: View {
    
    @Environment(\.rootNavigationPath) var rootNavigationPath
    
    @AppStorage(key: .cohabitantId) var cohabitantId = ""
    
    var body: some View {
        ZStack {
            if cohabitantId.isEmpty {
                NotRegisteredContent()
            }
            else {
                RegisteredContent()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationBarButton(label: .settings) {
                    rootNavigationPath.showSettingView()
                }
            }
        }
    }
}

#Preview("HomeView_未登録時") {
    NavigationStack {
        HomeView()
            .injectAppStorageWithPreview("HomeView_未登録時")
    }
}

#Preview("HomeView_登録時") {
    NavigationStack {
        HomeView()
            .injectAppStorageWithPreview("HomeView_登録時")
    }
}
