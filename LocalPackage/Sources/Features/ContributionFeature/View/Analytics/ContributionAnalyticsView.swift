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

    @Binding var selectedPeriod: DisplayPointPeriod

    let analytics: ContributionAnalytics?
    let myUserId: String
    let onJumpToLatest: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: .space16) {
                if let analytics {
                    if analytics.isEmpty {
                        emptyContent()
                    } else {
                        graphContent(data: analytics.currentList(calendar: calendar))
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
            }
            .padding(.top, .space16)
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
    
    func graphContent(data: AllUserViewablePointList) -> some View {
        VStack(spacing: .space16) {
            Text("指定期間中のポイントの獲得推移")
                .font(with: .headLineS)
                .frame(maxWidth: .infinity, alignment: .leading)
            PointsTimeSeriesChartView(viewableData: data)
                .frame(height: 240)
            Text("指定期間中の累計ポイントの推移")
                .font(with: .headLineS)
                .frame(maxWidth: .infinity, alignment: .leading)
            CumulativePointsAreaChartView(viewableData: AllUserCumulativeData.make(
                list: data.list,
                displayPeriod: data.displayPeriod
            ))
            .frame(height: 240)
        }
    }

    func emptyContent() -> some View {
        ContentUnavailableView {
            Label("この期間に達成された家事はありません", systemImage: "chart.bar.xaxis")
        } description: {
            Text("期間を変更すると過去の家事貢献度を確認できます")
        } actions: {
            Button("直近のデータがある期間を表示", action: onJumpToLatest)
                .subPrimaryButtonStyle()
        }
    }
}

// MARK: プレゼンテーションロジック

private extension ContributionAnalyticsView {}

#Preview("ContributionAnalyticsView_週間", traits: .sizeThatFitsLayout) {
    @Previewable @State var selectedPeriod = DisplayPointPeriod(
        type: .week,
        anchor: .previewDate(year: 2026, month: 4, day: 30)
    )
    ContributionAnalyticsView(
        selectedPeriod: $selectedPeriod,
        analytics: .makeForPreview(type: .week),
        myUserId: "user1",
        onJumpToLatest: {}
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
        onJumpToLatest: {}
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
        onJumpToLatest: {}
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
        onJumpToLatest: {}
    )
    .setupEnvironmentForPreview()
}
