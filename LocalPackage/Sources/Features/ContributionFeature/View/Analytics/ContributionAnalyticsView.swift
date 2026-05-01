//
//  ContributionAnalyticsView.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/01.
//

import SwiftUI

struct ContributionAnalyticsView: View {

    @Environment(\.now) var now
    @Environment(\.calendar) var calendar
    
    @Binding var selectedPeriod: DisplayPointPeriod
    let analytics: ContributionAnalytics?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .space8) {
                Text(chartTitle)
                    .font(with: .headLineS)
                    .foregroundStyle(.onSurface)
                    .padding(.horizontal, .space16)
                    .padding(.top, .space16)
                if let currentList = analytics?.currentList(calendar: calendar) {
                    PointsTimeSeriesChartView(viewableData: currentList)
                } else {
                    // TODO: データがない旨の空表示を実装する
                }
            }
        }
    }

    private var chartTitle: String {
        let month = calendar.component(.month, from: now)
        return "\(month)月のポイント推移"
    }
}
