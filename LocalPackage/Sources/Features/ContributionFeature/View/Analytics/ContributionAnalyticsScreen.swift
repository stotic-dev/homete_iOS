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
    @Environment(\.loginContext.account.id) var userId
    @LoadingState var loadingState

    @State var selectedPeriod: DisplayPointPeriod = .init(type: .month, anchor: .now)
    @State var analytics: ContributionAnalytics?

    public static func make() -> some View {
        ContributionAnalyticsScreen()
    }

    public var body: some View {
        ContributionAnalyticsView(
            selectedPeriod: $selectedPeriod,
            analytics: analytics,
            myUserId: userId,
            onJumpToLatest: jumpToLatestAchievedPeriod
        )
        .navigationTitle("家事分析")
        .task(id: contributionStore.contiribution) {
            await onChangeContribution()
        }
        .onChange(of: selectedPeriod) {
            loadingState.task {
                await onChangePeriod()
            }
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

        let contribution = contributionStore.contiribution
        analytics = await analytics?.updatePeriod(
            displayPeriod: selectedPeriod,
            members: members,
            contribution: contribution,
            calendar: calendar
        )
    }

    func jumpToLatestAchievedPeriod() {

        guard let latestDate = contributionStore.contiribution.latestAchievedDate else { return }
        let clampedAnchor = min(latestDate, now)
        selectedPeriod = .init(type: selectedPeriod.type, anchor: clampedAnchor)
    }
}
