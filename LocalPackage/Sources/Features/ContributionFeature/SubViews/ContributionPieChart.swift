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

    let summaries: AllUserPointSummary

    var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("家事達成割合")
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
                .padding(.top, .space16)
                .padding(.leading, .space16)
            Chart(summaries.items) { item in
                SectorMark(
                    angle: .value("件数", item.achievedCount),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("名前", item.userName))
            }
            .chartLegend(position: .bottom, alignment: .center)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ContributionPieChart(
        summaries: .init(items: [
            UserPointSummary(
                userId: "user1",
                userName: "田中",
                isMe: true,
                monthlyPoint: .init(value: 120),
                achievedCount: 5
            ),
            UserPointSummary(
                userId: "user2",
                userName: "佐藤",
                isMe: false,
                monthlyPoint: .init(value: 40),
                achievedCount: 2
            )
        ])
    )
    .frame(height: 240)
}
