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

    var body: some View {
        ScrollView {
            VStack(spacing: .space16) {
                if let currentList = analytics?.currentList(calendar: calendar) {
                    graphContent(data: currentList)
                } else {
                    // TODO: データがない旨の空表示を実装する
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
        analytics: .makeForPreview(type: .week)
    )
    .setupEnvironmentForPreview()
}
