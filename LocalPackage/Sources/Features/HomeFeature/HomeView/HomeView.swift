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

    public init() {}

    @Environment(CohabitantStore.self) var cohabitantStore
    @Environment(\.loginContext) var loginContext
    @Environment(\.routeResolver) var router
    @Environment(\.appDependencies.houseworkManager) var houseworkManager
    @Environment(\.now) var now
    @Environment(\.calendar) var calendar
    @State var isShowCohabitantRegistrationModal = false
    @State var isShowSetting = false
    @State private var contributionStore: ContributionStore?

    public var body: some View {
        NavigationStack {
            ZStack {
                if loginContext.hasCohabitant, let store = contributionStore {
                    RegisteredContent()
                        .environment(store)
                        .task {
                            await didAppearRegisteredContent()
                        }
                }
                else if !loginContext.hasCohabitant {
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
        .task(id: loginContext.hasCohabitant) {
            if loginContext.hasCohabitant, contributionStore == nil {
                contributionStore = ContributionStore(
                    houseworkManager: houseworkManager,
                    calendar: calendar
                )
            }
        }
    }
}

// MARK: プレゼンテーションロジック

private extension HomeView {

    func didAppearRegisteredContent() async {

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

        await cohabitantStore.removeSnapshotListener()
    }
}
