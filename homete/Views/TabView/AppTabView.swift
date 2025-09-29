//
//  AppTabView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/06.
//

import SwiftUI
import UserNotifications

struct AppTabView: View {
    
    @Environment(\.calendar) var calendar
    @Environment(\.cohabitantId) var cohabitantId
    @Environment(HouseworkListStore.self) var houseworkListStore
    
    @State var type: TabType = .dashboard
    
    var body: some View {
        ZStack {
            if #available(iOS 18.0, *) {
                TabView(selection: $type) {
                    Tab("ダッシュボード", systemImage: "list.bullet.clipboard.fill", value: .dashboard) {
                        HomeView()
                    }
                    Tab("家事", systemImage: "person.2.arrow.trianglehead.counterclockwise", value: .homework) {
                        HouseworkBoardView()
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
                }
            }
        }
        .onAppear {
           onAppear()
        }
        .onChange(of: cohabitantId) {
            Task {
                await onChangeCohabitantId()
            }
        }
    }
}

// MARK: プレゼンテーションロジック

private extension AppTabView {
    
    func onAppear() {
        
        requestNotificationPermission()
        reloadHouseworkList()
    }
    
    func onChangeCohabitantId() async {
        
        guard !cohabitantId.isEmpty else {
            
            await houseworkListStore.clear()
            return
        }
        reloadHouseworkList()
    }
}

private extension AppTabView {
    
    func requestNotificationPermission() {
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            
            if let error = error {
                
                print("[Notifications] Authorization error: \(error)")
                return
            }
            guard granted else {
                
                print("[Notifications] Authorization not granted.")
                return
            }
            
            DispatchQueue.main.async {
                
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func reloadHouseworkList() {
        Task {
            await houseworkListStore.loadHouseworkList(
                currentTime: .now,
                cohabitantId: cohabitantId,
                calendar: calendar
            )
        }
    }
}

extension AppTabView {
    
    enum TabType {
        
        case dashboard
        case homework
    }
}

#Preview {
    AppTabView()
        .environment(AccountStore(appDependencies: .previewValue))
        .environment(AccountAuthStore(appDependencies: .previewValue))
}
