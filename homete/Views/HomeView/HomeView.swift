//
//  HomeView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

struct HomeView: View {
        
    @AppStorage(key: .cohabitantId) var cohabitantId = ""
    
    @State var isShowCohabitantRegistrationModal = false
    @State var isShowSetting = false
    
    var body: some View {
        NavigationStack {
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
            .fullScreenCover(isPresented: $isShowCohabitantRegistrationModal) {
                CohabitantRegistrationView()
            }
            .sheet(isPresented: $isShowSetting) {
                SettingView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationBarButton(label: .settings) {
                        isShowSetting = true
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
