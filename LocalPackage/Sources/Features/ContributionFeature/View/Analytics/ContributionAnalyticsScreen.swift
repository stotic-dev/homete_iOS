//
//  ContributionAnalyticsScreen.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/29.
//

import HometeDomain
import HometeUI
import SwiftUI

public struct ContributionAnalyticsScreen: View {

    @Environment(ContributionStore.self) var contributionStore
    @Environment(\.cohabitantMembers) var members
    @Environment(\.calendar) var calendar
    @Environment(\.now) var now
    @Environment(\.loginContext) var loginContext
    @Environment(\.routeResolver) var router
    @Environment(\.houseworkStoragePolicy) var storagePolicy
    @LoadingState var loadingState

    @State var selectedPeriod: DisplayPointPeriod = .init(type: .month, anchor: .now)
    @State var analytics: ContributionAnalytics?
    @State var isShowPaywall = false

    public static func make() -> some View {
        ContributionAnalyticsScreen()
    }

    public var body: some View {
        ContributionAnalyticsView(
            selectedPeriod: $selectedPeriod,
            analytics: analytics,
            myUserId: loginContext.account.id,
            latestAchievedDate: contributionStore.contiribution.latestAchievedDate,
            onUpgradeTapped: { isShowPaywall = true }
        )
        .navigationTitle("家事分析")
        .softTopScrollEdgeEffect()
        .task(id: contributionStore.contiribution) {
            await onChangeContribution()
        }
        .onChange(of: selectedPeriod) {
            loadingState.task {
                await onChangePeriod()
            }
        }
        .fullScreenCoverOnIOS(isPresented: $isShowPaywall) {
            router.resolve(.paywall)
        }
    }

}

private extension ContributionAnalyticsScreen {

    func onChangeContribution() async {
        let contribution = contributionStore.contiribution
        analytics = await .make(
            contribution: contribution,
            members: members,
            displayPeriod: selectedPeriod,
            calendar: calendar
        )
    }

    func onChangePeriod() async {
        // 取得済み期間より過去に遡られた場合は、不足分をフェッチしてから集計し直す
        await fetchIfNeeded()
        let contribution = contributionStore.contiribution
        analytics = await analytics?.updatePeriod(
            displayPeriod: selectedPeriod,
            members: members,
            contribution: contribution,
            calendar: calendar
        )
    }

    /// 表示しようとしている期間が閲覧可能な範囲内であれば、未取得分を追加でフェッチする
    func fetchIfNeeded() async {
        guard let cohabitantId = loginContext.cohabitantId,
              let range = selectedPeriod.calcDateRange(calendar: calendar),
              storagePolicy.isViewable(range.lowerBound, currentDate: now, calendar: calendar) else { return }

        await contributionStore.fetchIfNeeded(
            until: range.lowerBound,
            cohabitantId: cohabitantId,
            calendar: calendar
        )
    }

}
