//
//  HomeView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import ContributionFeature
import HometeDomain
import HometeUI
import HouseworkFeature
import SwiftUI

public struct HomeView: View {

    @Environment(\.loginContext) var loginContext
    @Environment(\.routeResolver) var router
    @Environment(\.appDependencies.houseworkManager) var houseworkManager
    @Environment(\.now) var now
    @Environment(\.calendar) var calendar

    @State var isShowCohabitantRegistrationModal = false
    @State var isShowSetting = false
    @State var registeredContentNavigationPath = AppNavigationPath<RegisteredContentRoute>()
    let contributionStore: ContributionStore?
    let cohabitantStore: CohabitantStore?
    let houseworkTemplateListStore: HouseworkTemplateListStore?
    let houseworkListStore: HouseworkListStore?

    public var body: some View {
        NavigationStack(path: $registeredContentNavigationPath.path) {
            ZStack {
                VStack(spacing: .space16) {
                    if loginContext.hasCohabitant,
                       let contributionStore,
                       let cohabitantStore,
                       let houseworkListStore,
                       let houseworkTemplateListStore {
                        registeredContent(
                            contributionStore: contributionStore,
                            cohabitantStore: cohabitantStore,
                            houseworkTemplateListStore: houseworkTemplateListStore,
                            houseworkListStore: houseworkListStore
                        )
                    } else if !loginContext.hasCohabitant {
                        notRegisteredContent()
                    }
                }
                .fullScreenCoverOnIOS(isPresented: $isShowCohabitantRegistrationModal) {
                    router.resolve(.cohabitantRegistration)
                }
                .trailingToolbarItem {
                    NavigationBarButton(label: .settings) {
                        isShowSetting = true
                    }
                }
                .sheet(isPresented: $isShowSetting) {
                    router.resolve(.setting)
                }
            }
        }
    }

}

public extension HomeView {

    static func make(
        contributionStore: ContributionStore?,
        cohabitantStore: CohabitantStore?,
        houseworkTemplateListStore: HouseworkTemplateListStore?,
        houseworkListStore: HouseworkListStore?
    ) -> some View {
        HomeView(
            contributionStore: contributionStore,
            cohabitantStore: cohabitantStore,
            houseworkTemplateListStore: houseworkTemplateListStore,
            houseworkListStore: houseworkListStore
        )
    }

}

private extension HomeView {

    func registeredContent(
        contributionStore: ContributionStore,
        cohabitantStore: CohabitantStore,
        houseworkTemplateListStore: HouseworkTemplateListStore,
        houseworkListStore: HouseworkListStore
    ) -> some View {
        RegisteredContent()
            .task {
                await didAppearRegisteredContent(cohabitantStore: cohabitantStore)
            }
            .sheet(isPresented: $isShowSetting) {
                router.resolve(.setting)
            }
            .environment(contributionStore)
            .environment(cohabitantStore)
            .environment(houseworkTemplateListStore)
            .environment(houseworkListStore)
    }

    func notRegisteredContent() -> some View {
        NotRegisteredContent(
            isShowCohabitantRegistrationModal: $isShowCohabitantRegistrationModal
        )
        .task {
            await didAppearNotRegisteredContent()
        }
    }

}

// MARK: プレゼンテーションロジック

private extension HomeView {

    func didAppearRegisteredContent(cohabitantStore: CohabitantStore) async {
        guard let cohabitantId = loginContext.account.cohabitantId else {
            // パートナー登録完了後にcohabitantIdが無いケースは想定外なので表明としてassertionFailureを行う
            assertionFailure("Required param is nil(cohabitantId)")
            return
        }
        await cohabitantStore.addSnapshotListenerIfNeeded(cohabitantId)
        await houseworkManager.setupObserver(
            currentTime: now,
            cohabitantId: cohabitantId,
            calendar: calendar
        )
    }

    func didAppearNotRegisteredContent() async {
        await cohabitantStore?.removeSnapshotListener()
    }

}
