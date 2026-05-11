//
//  HomeView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import ContributionFeature
import HometeDomain
import HometeUI
import SwiftUI

public struct HomeView: View {

    @Environment(\.loginContext) var loginContext
    @Environment(\.routeResolver) var router
    @Environment(\.appDependencies.houseworkManager) var houseworkManager
    @Environment(\.now) var now
    @Environment(\.calendar) var calendar
    @State var isShowCohabitantRegistrationModal = false
    @State var isShowSetting = false
    let contributionStore: ContributionStore?
    let cohabitantStore: CohabitantStore?

    public var body: some View {
        NavigationStack {
            ZStack {
                if loginContext.hasCohabitant,
                   let contributionStore,
                   let cohabitantStore {
                    RegisteredContent()
                        .environment(contributionStore)
                        .environment(cohabitantStore)
                        .task {
                            await didAppearRegisteredContent(cohabitantStore: cohabitantStore)
                        }
                } else if !loginContext.hasCohabitant {
                    NotRegisteredContent(
                        isShowCohabitantRegistrationModal: $isShowCohabitantRegistrationModal
                    )
                    .task {
                        await didAppearNotRegisteredContent()
                    }
                }
            }
            .fullScreenCoverOnIOS(isPresented: $isShowCohabitantRegistrationModal) {
                router.resolve(.cohabitantRegistration)
            }
            .sheet(isPresented: $isShowSetting) {
                router.resolve(.setting)
            }
            .trailingToolbarItem {
                NavigationBarButton(label: .settings) {
                    isShowSetting = true
                }
            }
        }
    }

}

public extension HomeView {

    static func make(
        contributionStore: ContributionStore?,
        cohabitantStore: CohabitantStore?
    ) -> some View {
        HomeView(
            contributionStore: contributionStore,
            cohabitantStore: cohabitantStore
        )
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
