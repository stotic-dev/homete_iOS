//
//  ContributionGraphSection.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/28.
//

import SwiftUI

struct ContributionGraphSection: View {

    let summaries: [PointSummary]
    let userNames: [String: String]
    let myUserId: String

    var body: some View {
        #if os(iOS)
        TabView {
            charts
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .frame(height: 280)
        #else
        TabView {
            charts
        }
        .frame(height: 280)
        #endif
    }

    @ViewBuilder
    private var charts: some View {
        ContributionBarChart(
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
        summaries: [
            PointSummary(userId: "user1", monthlyPoint: 120, achievedCount: 5),
            PointSummary(userId: "user2", monthlyPoint: 40, achievedCount: 2)
        ],
        userNames: ["user1": "田中", "user2": "佐藤"],
        myUserId: "user1"
    )
}
