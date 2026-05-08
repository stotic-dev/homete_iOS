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

    let data: [UserHouseworkAchieved]

    var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            HStack(spacing: .zero) {
                Text("家事達成割合")
                    .font(with: .headLineS)
                    .foregroundStyle(.onSurface)
                Spacer()
                GraphDescriptionPopoverButton(
                    title: "家事達成割合とは？",
                    message: """
                    指定期間中において、達成した家事の数の合計からグループ内のユーザーの割合を示しています。
                    達成した家事の数の観点から、家事貢献度を図ることができます。
                    """
                )
            }
            .padding(.horizontal, .space16)
            Chart(data) { item in
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
        data: [
            .init(
                userId: "user1",
                userName: "田中",
                achievedCount: 5
            ),
            .init(
                userId: "user2",
                userName: "佐藤",
                achievedCount: 2
            )
        ]
    )
    .frame(height: 240)
}
