//
//  SummaryPointBarChart.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/28.
//

import Charts
import HometeUI
import SwiftUI

struct SummaryPointBarChart: View {

    let summaries: AllUserPointSummary

    var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("月間ポイント比較")
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
                .padding(.top, .space16)
                .padding(.leading, .space16)
            Chart(summaries.items) { item in
                BarMark(
                    x: .value("ユーザー", item.userName),
                    y: .value("ポイント", item.monthlyPoint.value)
                )
                .foregroundStyle(item.isMe ? Color.primary2 : Color.secondary)
                .annotation(position: .top) {
                    Text("\(item.monthlyPoint.value)pt")
                        .font(with: .caption)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis(.hidden)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    SummaryPointBarChart(
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
