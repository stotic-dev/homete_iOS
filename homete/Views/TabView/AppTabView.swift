//
//  AppTabView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import SwiftUI

struct AppTabView: View {
    
    @State var type: TabType = .dashboard
    
    var body: some View {
        if #available(iOS 18.0, *) {
            TabView(selection: $type) {
                Tab("ダッシュボード", systemImage: "list.bullet.clipboard.fill", value: .dashboard) {
                    HomeView()
                }
                Tab("家事", systemImage: "person.2.arrow.trianglehead.counterclockwise", value: .dashboard) {
                    HouseworkBoardView()
                }
                Tab("設定", systemImage: "gear", value: .dashboard) {
                    SettingView()
                }
            }
        } else {
            TabView(selection: $type) {
                HomeView()
                    .tag(TabType.dashboard)
                    .tabItem {
                        Label("ダッシュボード", systemImage: "ダッシュボード")
                    }
                HouseworkBoardView()
                    .tag(TabType.homework)
                    .tabItem {
                        Label(
                            "list.bullet.clipboard.fill",
                            systemImage: "person.2.arrow.trianglehead.counterclockwise"
                        )
                    }
                SettingView()
                    .tag(TabType.settings)
                    .tabItem {
                        Label("設定", systemImage: "gear")
                    }
            }
        }
    }
}

extension AppTabView {
    
    enum TabType {
        
        case dashboard
        case homework
        case settings
    }
}

#Preview {
    AppTabView()
        .environment(AccountStore(appDependencies: .previewValue))
        .environment(AccountAuthStore(appDependencies: .previewValue))
}
