//
//  ContributionGraphSection.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/28.
//

import SwiftUI

struct ContributionGraphSection: View {

    let summaries: AllUserPointSummary
    let userNames: [String: String]
    let myUserId: String

    var body: some View {
        #if os(iOS)
        TabView {
            charts
                .padding(.bottom, .space48)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .frame(height: 300)
        #else
        TabView {
            charts
        }
        .frame(height: 280)
        #endif
    }

    @ViewBuilder
    private var charts: some View {
        SummaryPointBarChart(
            summaries: summaries,
            userNames: userNames,
            myUserId: myUserId
        )
        ContributionPieChart(
            summaries: summaries,
            userNames: userNames
        )
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ContributionGraphSection(
        summaries: .init(items: [
            UserPointSummary(userId: "user1", userName: "田中", isMe: true, monthlyPoint: .init(value: 120), achievedCount: 5),
            UserPointSummary(userId: "user2", userName: "佐藤", isMe: false, monthlyPoint: .init(value: 40), achievedCount: 2)
        ]),
        userNames: ["user1": "田中", "user2": "佐藤"],
        myUserId: "user1"
    )
}
