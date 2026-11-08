//
//  ContributionSummaryComponent.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import ContributionFeatureUI
import HometeAppCore
import HometeDomain
import HometeUI
import SwiftUI

public struct ContributionSummaryComponent: View {

    @Environment(ContributionStore.self) var contributionStore
    @Environment(\.cohabitantMembers) var members
    @Environment(\.loginContext.account.id) var userId
    @Environment(\.now) var now
    @Environment(\.calendar) var calendar
    @Environment(\.appDependencies.intentDonationClient) var intentDonationClient
    /// プレビューやチュートリアルでは注入されないため、無くても描画できるようにする
    @Environment(PendingRouteStore.self) var pendingRouteStore: PendingRouteStore?

    @State var summary: AllUserPointSummary = .init()
    @State var isShowAnalytics = false

    public static func make() -> some View {
        ContributionSummaryComponent()
    }

    public var body: some View {
        ContributionSummaryContent(summaries: summary) {
            // 分析を見る習慣をSiriやロック画面で提案してもらえるよう、自分で開いたときだけ伝える。
            // App Intentから開いたときは、OSがIntentの実行として記録するため伝えない
            intentDonationClient.donateContributionSummary()
            isShowAnalytics = true
        }
        .onChange(of: members) {
            Task {
                await onChangeContribution()
            }
        }
        .task(id: contributionStore.contiribution) {
            await onChangeContribution()
        }
        // App Intentから分析画面を開く。分析画面への遷移はこのコンポーネントが持っている
        .onChange(of: pendingRouteStore?.pendingRoute, initial: true) {
            if pendingRouteStore?.takeContributionAnalytics() == true {
                isShowAnalytics = true
            }
        }
        .navigationDestination(isPresented: $isShowAnalytics) {
            ContributionAnalyticsScreen.make()
                .environment(contributionStore)
        }
    }

}

private extension ContributionSummaryComponent {

    func onChangeContribution() async {
        let contribution = contributionStore.contiribution
        print("did change contribution: \(contribution), members: \(members)")

        let myUserId = userId

        let summary = await Task.detached {
            await contribution.calculatePointSummaries(
                month: now,
                calendar: calendar,
                members: members,
                myUserId: myUserId
            )
        }.value

        withAnimation {
            self.summary = summary
        }
    }

}
