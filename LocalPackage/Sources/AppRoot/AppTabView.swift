//
//  AppTabView.swift
//

import HomeFeature
import HometeDomain
import HouseworkFeature
import HometeUI
import SwiftUI
import UserNotifications

struct AppTabView: View {

    @Environment(\.loginContext.account.cohabitantId) var cohabitantId

    @State var type: TabType = .dashboard

    var body: some View {
        ZStack {
            if #available(iOS 18.0, *) {
                TabView(selection: $type) {
                    Tab(
                        "ダッシュボード",
                        systemImage: "list.bullet.clipboard.fill",
                        value: .dashboard
                    ) {
                        HomeView()
                    }
                    Tab(
                        "家事",
                        systemImage: "person.2.arrow.trianglehead.counterclockwise",
                        value: .homework
                    ) {
                        HouseworkBoardView.instantiate()
                    }
                }
            } else {
                TabView(selection: $type) {
                    HomeView()
                        .tag(TabType.dashboard)
                        .tabItem {
                            Label(
                                "ダッシュボード",
                                systemImage: "list.bullet.clipboard.fill"
                            )
                        }
                    HouseworkBoardView.instantiate()
                        .tag(TabType.homework)
                        .tabItem {
                            Label(
                                "家事",
                                systemImage: "person.2.arrow.trianglehead.counterclockwise"
                            )
                        }
                }
            }
        }
        .task {
           await onAppear()
        }
    }
}

// MARK: プレゼンテーションロジック

private extension AppTabView {

    func onAppear() async {

        await requestNotificationPermission()
    }
}

private extension AppTabView {

    func requestNotificationPermission() async {

        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                print("[Notifications] Authorization not granted.")
                return
            }
            #if os(iOS)
            UIApplication.shared.registerForRemoteNotifications()
            #endif
        } catch {
            print("[Notifications] Authorization error: \(error)")
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
        .environment(AccountStore())
        .environment(AccountAuthStore())
        .environment(CohabitantStore())
}
