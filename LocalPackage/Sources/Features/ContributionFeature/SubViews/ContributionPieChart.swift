//
//  ContributionPieChart.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/28.
//

import Charts
import HometeUI
import SwiftUI

struct ContributionPieChart: View {

    let summaries: [PointSummary]
    let userNames: [String: String]

    var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("家事達成割合")
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
                .padding(.top, .space16)
                .padding(.leading, .space16)
            if summaries.allSatisfy({ $0.achievedCount == 0 }) {
                ContentUnavailableView("今月の達成家事はありません", systemImage: "checkmark.circle")
                    .frame(height: 180)
            } else {
                Chart(summaries) { item in
                    SectorMark(
                        angle: .value("件数", item.achievedCount),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("名前", userNames[item.userId] ?? item.userId))
                }
                .chartLegend(position: .bottom, alignment: .center)
                .frame(height: 180)
                .padding(.horizontal, .space16)
                .padding(.bottom, .space40)
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ContributionPieChart(
        summaries: [
            PointSummary(userId: "user1", monthlyPoint: 120, achievedCount: 5),
            PointSummary(userId: "user2", monthlyPoint: 40, achievedCount: 2)
        ],
        userNames: ["user1": "田中", "user2": "佐藤"]
    )
}
