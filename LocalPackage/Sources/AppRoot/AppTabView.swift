//
//  AppTabView.swift
//

import ContributionFeature
import HomeFeature
import HometeDomain
import HometeUI
import HouseworkFeature
import HouseworkTemplateFeature
import SwiftUI

struct AppTabView: View {

    @Environment(\.appDependencies) var appDependencies
    @Environment(\.loginContext) var loginContext
    @Environment(\.calendar) var calendar
    @Environment(SubscriptionStore.self) var subscriptionStore
    @Environment(PendingInvitationStore.self) var pendingInvitationStore
    @Environment(\.routeResolver) var router

    @State var cohabitantStore: CohabitantStore?
    @State var contributionStore: ContributionStore?
    @State var houseworkListStore: HouseworkListStore?
    @State var houseworkTemplateListStore: HouseworkTemplateListStore?
    @State var type: TabType = .dashboard

    var handler: Binding<TabType> {
        Binding(
            get: { type },
            set: {
                if $0 == type {
                    NotificationCenter.default.post(
                        name: .onTapAppAlreadySelectedTabItem,
                        object: nil,
                        userInfo: OnTapAppAlreadySelectedTabItemContext.makeUserInfo(from: $0)
                    )
                }
                type = $0
            }
        )
    }

    /// 招待リンクの参加画面を表示するかどうか
    /// - Note: 閉じられたら未処理のトークンを破棄して、同じ招待で再表示されないようにする
    var isPresentingCohabitantJoin: Binding<Bool> {
        Binding(
            get: { pendingInvitationStore.pendingToken != nil },
            set: { isPresenting in
                if !isPresenting {
                    pendingInvitationStore.clear()
                }
            }
        )
    }

    var body: some View {
        tabView()
            .fullScreenCoverOnIOS(isPresented: isPresentingCohabitantJoin) {
                if let token = pendingInvitationStore.pendingToken {
                    router.resolve(.cohabitantJoin(token: token))
                }
            }
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
            .environment(
                \.houseworkTemplateContext,
                houseworkTemplateListStore?.context ?? .init(metadata: nil, houseworkTemplate: [])
            )
            .environment(
                \.houseworkStoragePolicy,
                HouseworkStoragePolicy(isPremium: subscriptionStore.isPremium)
            )
    }

}

// MARK: UI定義

private extension AppTabView {

    func tabView() -> some View {
        ZStack {
            if #available(iOS 18.0, *) {
                TabView(selection: handler) {
                    Tab(
                        "ダッシュボード",
                        systemImage: "list.bullet.clipboard.fill",
                        value: .dashboard
                    ) {
                        homeScreen
                    }
                    Tab(
                        "家事",
                        systemImage: "person.2.arrow.trianglehead.counterclockwise",
                        value: .homework
                    ) {
                        houseworkBoardScreen
                    }
                }
            } else {
                TabView(selection: handler) {
                    homeScreen
                        .tag(TabType.dashboard)
                        .tabItem {
                            Label(
                                "ダッシュボード",
                                systemImage: "list.bullet.clipboard.fill"
                            )
                        }
                    houseworkBoardScreen
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

    var homeScreen: some View {
        HomeView.make(
            contributionStore: contributionStore,
            cohabitantStore: cohabitantStore,
            houseworkTemplateListStore: houseworkTemplateListStore,
            houseworkListStore: houseworkListStore
        )
    }

    var houseworkBoardScreen: some View {
        HouseworkBoardScreen.make(
            houseworkListStore: houseworkListStore,
            houseworkTemplateListStore: houseworkTemplateListStore
        )
    }

}

// MARK: プレゼンテーションロジック

private extension AppTabView {

    func onAppear() async {
        setupStore()
        await startObserveTemplateIfNeeded()
    }

    func onChangeCohabitantId() {
        setupStore()
    }

}

private extension AppTabView {

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
        houseworkTemplateListStore = .init(
            houseworkTemplateClient: appDependencies.houseworkTemplateClient
        )
    }

    func startObserveTemplateIfNeeded() async {
        guard let store = houseworkTemplateListStore,
              let cohabitantId = loginContext.cohabitantId else { return }

        do {
            try await store.configure(cohabitantId: cohabitantId)
        } catch {
            // TODO: エラーハンドリング
        }
    }

}

#Preview {
    AppTabView()
        .environment(AccountStore())
        .environment(AccountAuthStore())
        .environment(PendingInvitationStore())
    #if canImport(Prefire)
        .prefireIgnored()
    #endif
}
