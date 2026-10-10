//
//  ContributionPieChart.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/28.
//

import Charts
import HometeDomain
import HometeUI
import SwiftUI

struct ContributionPieChart: View {

    let data: [UserHouseworkAchieved]

    var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            HStack(spacing: .zero) {
                Text("家事達成割合", bundle: #bundle)
                    .font(with: .headLineS)
                    .foregroundStyle(.textPrimary)
                Spacer()
                DescriptionPopoverButton(
                    title: .localized("家事達成割合とは？"),
                    message: .localized("""
                    指定期間中において、達成した家事の数の合計からグループ内のユーザーの割合を示しています。
                    達成した家事の数の観点から、家事貢献度を図ることができます。
                    """)
                )
            }
            .padding(.horizontal, .space16)
            Chart(data) { item in
                SectorMark(
                    angle: .value(.localized("件数"), item.achievedCount),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(by: .value(.localized("名前"), item.userName))
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
            ),
        ]
    )
    .frame(height: 240)
}
