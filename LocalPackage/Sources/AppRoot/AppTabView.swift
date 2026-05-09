//
//  AppTabView.swift
//

import ContributionFeature
import HomeFeature
import HometeDomain
import HouseworkFeature
import HometeUI
import SwiftUI
import UserNotifications

struct AppTabView: View {
    
    @Environment(\.appDependencies) var appDependencies
    @Environment(\.loginContext) var loginContext
    @Environment(\.calendar) var calendar

    @State var cohabitantStore: CohabitantStore?
    @State var contributionStore: ContributionStore?
    @State var houseworkListStore: HouseworkListStore?
    @State var type: TabType = .dashboard

    var body: some View {
        tabView()
            .task {
                await onAppear()
            }
            .onChange(of: loginContext.cohabitantId) {
                onChangeCohabitantId()
            }
            .environment(
                \.cohabitantMembers,
                 cohabitantStore?.members ?? .init(value: [], ownId: "")
            )
    }
}

// MARK: UI定義

private extension AppTabView {
    
    func tabView() -> some View {
        ZStack {
            if #available(iOS 18.0, *) {
                TabView(selection: $type) {
                    Tab(
                        "ダッシュボード",
                        systemImage: "list.bullet.clipboard.fill",
                        value: .dashboard
                    ) {
                        HomeView.make(
                            contributionStore: contributionStore,
                            cohabitantStore: cohabitantStore
                        )
                    }
                    Tab(
                        "家事",
                        systemImage: "person.2.arrow.trianglehead.counterclockwise",
                        value: .homework
                    ) {
                        HouseworkBoardScreen.make(houseworkListStore: houseworkListStore)
                    }
                }
            } else {
                TabView(selection: $type) {
                    HomeView.make(
                        contributionStore: contributionStore,
                        cohabitantStore: cohabitantStore
                    )
                    .tag(TabType.dashboard)
                    .tabItem {
                        Label(
                            "ダッシュボード",
                            systemImage: "list.bullet.clipboard.fill"
                        )
                    }
                    HouseworkBoardScreen.make(houseworkListStore: houseworkListStore)
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
    }
}

// MARK: プレゼンテーションロジック

private extension AppTabView {

    func onAppear() async {

        setupStore()
        await requestNotificationPermission()
    }
    
    func onChangeCohabitantId() {
        
        setupStore()
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
    
    func setupStore() {
        
        guard loginContext.hasCohabitant else {
            
            cohabitantStore = nil
            contributionStore = nil
            return
        }
        cohabitantStore = .init(
            ownId: loginContext.account.id,
            cohabitantClient: appDependencies.cohabitantClient,
            accountInfoClient: appDependencies.accountInfoClient
        )
        contributionStore = .init(
            houseworkManager: appDependencies.houseworkManager,
            calendar: calendar
        )
        houseworkListStore = .init(
            houseworkClient: appDependencies.houseworkClient,
            cohabitantPushNotificationClient: appDependencies.cohabitantPushNotificationClient,
            houseworkManager: appDependencies.houseworkManager
        )
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
}
