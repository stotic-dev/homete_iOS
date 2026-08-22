//
//  ContributionAnalyticsView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/01.
//

import HometeDomain
import HometeUI
import SwiftUI
#if canImport(Prefire)
import Prefire
#endif

struct ContributionAnalyticsView: View {

    @Environment(\.calendar) var calendar
    @Environment(\.locale) var locale
    @Environment(\.now) var now
    @Environment(\.houseworkStoragePolicy) var storagePolicy

    @Binding var selectedPeriod: DisplayPointPeriod

    let analytics: ContributionAnalytics?
    let myUserId: String
    let latestAchievedDate: Date?
    let onUpgradeTapped: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: .space16) {
                if isOverStoragePeriod {
                    StoragePeriodLimitView(onUpgradeTapped: onUpgradeTapped)
                } else if let analytics {
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

    /// 表示中の期間が保存期間の上限より過去にはみ出しているか
    var isOverStoragePeriod: Bool {
        guard let range = selectedPeriod.calcDateRange(calendar: calendar) else { return false }

        return !storagePolicy.isViewable(range.lowerBound, currentDate: now, calendar: calendar)
    }

    func tappedLatestAchievedPeriodShowButton() {
        guard let latestDate = latestAchievedDate else { return }
        let clampedAnchor = min(latestDate, now)
        selectedPeriod = .init(type: selectedPeriod.type, anchor: clampedAnchor)
    }

}

#if DEBUG
private extension View {

    /// 保存期間の判定に関わる環境値をプレビュー用に固定する
    ///
    /// `\.now`の既定値は実行時の現在日時のため、固定のanchorを持つプレビューは
    /// 時間が経つだけでグラフから「保存期間外」表示へ勝手に切り替わってしまう。
    /// プランの出し分けは専用のプレビューで確認するため、ここではプレミアム固定にする。
    func setupStorageEnvironmentForPreview() -> some View {
        environment(\.now, .previewDate(year: 2026, month: 4, day: 30))
            .environment(\.houseworkStoragePolicy, .premium)
    }

}

#Preview("ContributionAnalyticsView_週間", traits: .sizeThatFitsLayout) {
    @Previewable @State var selectedPeriod = DisplayPointPeriod(
        type: .week,
        anchor: .previewDate(year: 2026, month: 4, day: 30)
    )
    ContributionAnalyticsView(
        selectedPeriod: $selectedPeriod,
        analytics: .makeForPreview(type: .week),
        myUserId: "user1",
        latestAchievedDate: nil,
        onUpgradeTapped: {}
    )
    .setupEnvironmentForPreview()
    .setupStorageEnvironmentForPreview()
    #if canImport(Prefire)
        .snapshot(perceptualPrecision: 0.95)
    #endif
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
        latestAchievedDate: nil,
        onUpgradeTapped: {}
    )
    .setupEnvironmentForPreview()
    .setupStorageEnvironmentForPreview()
    #if canImport(Prefire)
        .snapshot(perceptualPrecision: 0.95)
    #endif
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
        latestAchievedDate: nil,
        onUpgradeTapped: {}
    )
    .setupEnvironmentForPreview()
    .setupStorageEnvironmentForPreview()
    #if canImport(Prefire)
        .snapshot(perceptualPrecision: 0.95)
    #endif
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
        latestAchievedDate: nil,
        onUpgradeTapped: {}
    )
    .setupEnvironmentForPreview()
    .setupStorageEnvironmentForPreview()
}

#Preview("ContributionAnalyticsView_保存期間外", traits: .sizeThatFitsLayout) {
    @Previewable @State var selectedPeriod = DisplayPointPeriod(
        type: .month,
        anchor: .previewDate(year: 2025, month: 4, day: 30)
    )
    ContributionAnalyticsView(
        selectedPeriod: $selectedPeriod,
        analytics: .makeForPreview(type: .month),
        myUserId: "user1",
        latestAchievedDate: nil,
        onUpgradeTapped: {}
    )
    .setupEnvironmentForPreview()
    .environment(\.now, .previewDate(year: 2026, month: 4, day: 30))
    .environment(\.houseworkStoragePolicy, .free)
    #if canImport(Prefire)
        .snapshot(perceptualPrecision: 0.95)
    #endif
}
#endif
