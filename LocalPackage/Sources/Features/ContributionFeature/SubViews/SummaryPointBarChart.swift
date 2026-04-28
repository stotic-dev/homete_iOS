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

    let summaries: [UserPointSummary]
    let userNames: [String: String]
    let myUserId: String

    var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("月間ポイント比較")
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
                .padding(.top, .space16)
                .padding(.leading, .space16)
            Chart(summaries) { item in
                BarMark(
                    x: .value("ユーザー", userNames[item.userId] ?? item.userId),
                    y: .value("ポイント", item.monthlyPoint.value)
                )
                .foregroundStyle(item.userId == myUserId ? Color.primary2 : Color.secondary)
                .annotation(position: .top) {
                    Text("\(item.monthlyPoint.value)pt")
                        .font(with: .caption)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 180)
            .padding(.horizontal, .space16)
            .padding(.bottom, .space40)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    SummaryPointBarChart(
        summaries: [
            UserPointSummary(userId: "user1", monthlyPoint: .init(value: 120), achievedCount: 5),
            UserPointSummary(userId: "user2", monthlyPoint: .init(value: 40), achievedCount: 2)
        ],
        userNames: ["user1": "田中", "user2": "佐藤"],
        myUserId: "user1"
    )
}
