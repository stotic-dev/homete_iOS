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
    let userNames: [String: String]
    let myUserId: String

    var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("月間ポイント比較")
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
                .padding(.top, .space16)
                .padding(.leading, .space16)
            if summaries.hasData {
                Chart(summaries.items) { item in
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
            } else {
                ContentUnavailableView("達成した家事はありません", systemImage: "checkmark.circle")
            }
        }
    }
}

#Preview("SummaryPointBarChart_データ有り", traits: .sizeThatFitsLayout) {
    SummaryPointBarChart(
        summaries: .init(items: [
            UserPointSummary(userId: "user1", userName: "田中", isMe: true, monthlyPoint: .init(value: 120), achievedCount: 5),
            UserPointSummary(userId: "user2", userName: "佐藤", isMe: false, monthlyPoint: .init(value: 40), achievedCount: 2)
        ]),
        userNames: ["user1": "田中", "user2": "佐藤"],
        myUserId: "user1"
    )
    .frame(height: 240)
}

#Preview("SummaryPointBarChart_データ無し", traits: .sizeThatFitsLayout) {
    SummaryPointBarChart(
        summaries: .init(),
        userNames: [:],
        myUserId: "user1"
    )
    .frame(height: 240)
}
