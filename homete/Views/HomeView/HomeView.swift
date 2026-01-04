//
//  HomeView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

struct HomeView: View {
    
    @Environment(CohabitantStore.self) var cohabitantStore
    @Environment(\.loginContext) var loginContext
    @State var isShowCohabitantRegistrationModal = false
    @State var isShowSetting = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if loginContext.hasCohabitant {
                    RegisteredContent()
                        .task {
                            await didAppearRegisteredContent()
                        }
                }
                else {
                    NotRegisteredContent(
                        isShowCohabitantRegistrationModal: $isShowCohabitantRegistrationModal
                    )
                    .task {
                        await didAppearNotRegisteredContent()
                    }
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

// MARK: プレゼンテーションロジック

private extension HomeView {
    
    func didAppearRegisteredContent() async {
        
        guard let cohabitantId = loginContext.account.cohabitantId else {
            preconditionFailure("Required param is nil(cohabitantId)")
        }
        await cohabitantStore.addSnapshotListenerIfNeeded(cohabitantId)
    }
    
    func didAppearNotRegisteredContent() async {
        
        await cohabitantStore.removeSnapshotListener()
    }
}

#Preview("HomeView_未登録時") {
    NavigationStack {
        HomeView()
            .injectAppStorageWithPreview("HomeView_未登録時")
    }
    .environment(CohabitantStore())
}

#Preview("HomeView_登録時") {
    NavigationStack {
        HomeView()
            .environment(\.loginContext, .init(account: .init(
                id: "",
                userName: "",
                fcmToken: nil,
                cohabitantId: "dummy"
            )))
    }
    .environment(CohabitantStore())
}
