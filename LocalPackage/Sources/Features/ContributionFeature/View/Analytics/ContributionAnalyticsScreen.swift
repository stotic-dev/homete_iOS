//
//  ContributionAnalyticsScreen.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/29.
//

import HometeDomain
import HometeUI
import SwiftUI

struct ContributionAnalyticsScreen: View {
    
    @Environment(CohabitantStore.self) var cohabitantStore
    @Environment(ContributionStore.self) var contributionStore
    @Environment(\.calendar) var calendar
    @LoadingState var loadingState
    
    @State var selectedPeriod: DisplayPointPeriod = .init(type: .month, anchor: .now)
    @State var analytics: ContributionAnalytics?
    
    var body: some View {
        ContributionAnalyticsView(
            selectedPeriod: $selectedPeriod,
            analytics: analytics
        )
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
        let members = cohabitantStore.members
        analytics = await .make(
            contribution: contribution,
            members: members,
            displayPeriod: selectedPeriod,
            calendar: calendar
        )
    }
    
    func onChangePeriod() async {
        
        let contribution = contributionStore.contiribution
        let members = cohabitantStore.members
        analytics = await analytics?.updatePeriod(
            displayPeriod: selectedPeriod,
            members: members,
            contribution: contribution,
            calendar: calendar
        )
    }
}
