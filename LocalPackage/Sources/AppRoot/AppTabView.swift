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

    @Environment(\.calendar) var calendar
    @Environment(\.loginContext.account.cohabitantId) var cohabitantId
    @Environment(HouseworkListStore.self) var houseworkListStore

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

        requestNotificationPermission()

        guard let cohabitantId else { return }
        await houseworkListStore.loadHouseworkList(
            currentTime: .now,
            cohabitantId: cohabitantId,
            calendar: calendar
        )
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

            #if os(iOS)
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
            #endif
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
        .environment(HouseworkListStore(
            houseworkClient: .previewValue,
            cohabitantPushNotificationClient: .previewValue
        ))
        .environment(CohabitantStore())
}
