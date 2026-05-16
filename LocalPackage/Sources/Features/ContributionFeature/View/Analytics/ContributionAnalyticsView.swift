//
//  ContributionAnalyticsView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/01.
//

import HometeUI
import SwiftUI

struct ContributionAnalyticsView: View {

    @Environment(\.calendar) var calendar
    @Environment(\.locale) var locale
    @Environment(\.now) var now

    @Binding var selectedPeriod: DisplayPointPeriod

    let analytics: ContributionAnalytics?
    let myUserId: String
    let latestAchievedDate: Date?

    var body: some View {
        ScrollView {
            VStack(spacing: .space16) {
                if let analytics {
                    if analytics.isEmpty {
                        emptyContent()
                    } else {
                        graphContent(analytics: analytics)
                    }
                }
            }
            .padding(.top, .space16)
            .padding(.bottom, .space24)
            .padding(.horizontal, .space16)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            AnalyticsPeriodHeader(selectedPeriod: $selectedPeriod)
                .padding(.horizontal, .space16)
                .padding(.vertical, .space8)
        }
    }

}

// MARK: SubView

private extension ContributionAnalyticsView {

    func graphContent(analytics: ContributionAnalytics) -> some View {
        VStack(spacing: .space32) {
            pointGraph(pointData: analytics.currentList(calendar: calendar))
            ContributionPieChart(data: analytics.achieved())
                .frame(height: 240)
            AnalyticsRankingSection(
                pointRanking: analytics.ranking(
                    criterion: .point,
                    myUserId: myUserId,
                    calendar: calendar
                ),
                achievementRanking: analytics.ranking(
                    criterion: .achievement,
                    myUserId: myUserId,
                    calendar: calendar
                ),
                selectedPriodType: selectedPeriod.type
            )
        }
    }

    @ViewBuilder
    func pointGraph(pointData: AllUserViewablePointList) -> some View {
        PointsTimeSeriesChartView(viewableData: pointData)
            .frame(height: 240)
        CumulativePointsAreaChartView(viewableData: AllUserCumulativeData.make(
            list: pointData.list,
            displayPeriod: pointData.displayPeriod
        ))
        .frame(height: 240)
    }

    func emptyContent() -> some View {
        ContentUnavailableView {
            Label("この期間に達成された家事はありません", systemImage: "chart.bar.xaxis")
        } description: {
            Text("期間を変更すると過去の家事貢献度を確認できます")
        } actions: {
            Button("直近のデータがある期間を表示") {
                tappedLatestAchievedPeriodShowButton()
            }
            .subPrimaryButtonStyle()
        }
    }

}

// MARK: プレゼンテーションロジック

private extension ContributionAnalyticsView {

    func tappedLatestAchievedPeriodShowButton() {
        guard let latestDate = latestAchievedDate else { return }
        let clampedAnchor = min(latestDate, now)
        selectedPeriod = .init(type: selectedPeriod.type, anchor: clampedAnchor)
    }

}

#if DEBUG
#Preview("ContributionAnalyticsView_週間", traits: .sizeThatFitsLayout) {
    @Previewable @State var selectedPeriod = DisplayPointPeriod(
        type: .week,
        anchor: .previewDate(year: 2026, month: 4, day: 30)
    )
    ContributionAnalyticsView(
        selectedPeriod: $selectedPeriod,
        analytics: .makeForPreview(type: .week),
        myUserId: "user1",
        latestAchievedDate: nil
    )
    .setupEnvironmentForPreview()
}

#Preview("ContributionAnalyticsView_月間", traits: .sizeThatFitsLayout) {
    @Previewable @State var selectedPeriod = DisplayPointPeriod(
        type: .month,
        anchor: .previewDate(year: 2026, month: 4, day: 30)
    )
    ContributionAnalyticsView(
        selectedPeriod: $selectedPeriod,
        analytics: .makeForPreview(type: .month),
        myUserId: "user1",
        latestAchievedDate: nil
    )
    .setupEnvironmentForPreview()
}

#Preview("ContributionAnalyticsView_年間", traits: .sizeThatFitsLayout) {
    @Previewable @State var selectedPeriod = DisplayPointPeriod(
        type: .year,
        anchor: .previewDate(year: 2026, month: 4, day: 30)
    )
    ContributionAnalyticsView(
        selectedPeriod: $selectedPeriod,
        analytics: .makeForPreview(type: .year),
        myUserId: "user1",
        latestAchievedDate: nil
    )
    .setupEnvironmentForPreview()
}

#Preview("ContributionAnalyticsView_空表示", traits: .sizeThatFitsLayout) {
    @Previewable @State var selectedPeriod = DisplayPointPeriod(
        type: .month,
        anchor: .previewDate(year: 2026, month: 4, day: 30)
    )
    ContributionAnalyticsView(
        selectedPeriod: $selectedPeriod,
        analytics: .makeForTest(displayPeriod: selectedPeriod),
        myUserId: "user1",
        latestAchievedDate: nil
    )
    .setupEnvironmentForPreview()
}
#endif
