//
//  HomeView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

struct HomeView: View {
        
    @AppStorage(key: .cohabitantId) var cohabitantId = ""
    
    @State var navigationPath = CustomNavigationPath<HomeNavigationPathElement>(path: [])
    @State var isShowCohabitantRegistrationModal = false
    
    var body: some View {
        NavigationStack(path: $navigationPath.path) {
            ZStack {
                if cohabitantId.isEmpty {
                    NotRegisteredContent(
                        isShowCohabitantRegistrationModal: $isShowCohabitantRegistrationModal
                    )
                }
                else {
                    RegisteredContent()
                }
            }
            .environment(\.homeNavigationPath, navigationPath)
            .navigationDestination(for: HomeNavigationPathElement.self) { element in
                element.destination()
            }
            .fullScreenCover(isPresented: $isShowCohabitantRegistrationModal) {
                CohabitantRegistrationView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationBarButton(label: .settings) {
                        navigationPath.push(.settings)
                    }
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
            .injectAppStorageWithPreview("HomeView_登録時") {
                $0.set("testId", forKey: "cohabitantId")
            }
    }
}
