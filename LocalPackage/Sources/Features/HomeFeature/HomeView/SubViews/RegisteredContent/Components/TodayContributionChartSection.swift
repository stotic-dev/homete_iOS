//
//  TodayContributionChartSection.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/09/26.
//

import Charts
import HometeUI
import HouseworkFeature
import SwiftUI

/// 今日の家事の数・ポイントのメンバー別割合を、ドーナツグラフ2枚で表示する
struct TodayContributionChartSection: View {

    let contributions: [TodayMemberContribution]

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

}

// MARK: - UI定義

private extension TodayContributionChartSection {

    @ViewBuilder
    var charts: some View {
        donutChart(title: "完了した家事の数", valueLabel: "件数") {
            ($0.completedCount, "\($0.completedCount)件")
        }
        donutChart(title: "獲得したポイント", valueLabel: "ポイント") {
            ($0.point, "\($0.point)pt")
        }
    }

    func donutChart(
        title: LocalizedStringKey,
        valueLabel: String,
        value: @escaping (TodayMemberContribution) -> (Int, String)
    ) -> some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text(title)
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
            Chart(contributions) { item in
                let (amount, amountText) = value(item)
                SectorMark(
                    angle: .value(valueLabel, amount),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("名前", item.userName))
                .annotation(position: .overlay) {
                    if amount > 0 {
                        Text(amountText)
                            .font(with: .caption)
                            .foregroundStyle(.white)
                    }
                }
            }
            // 実績0のメンバーは扇形が無いため、凡例から漏れないよう全員を明示する
            .chartForegroundStyleScale(domain: contributions.map(\.userName))
            .chartLegend(position: .bottom, alignment: .center)
        }
    }

}

#Preview("TodayContributionChartSection_2人とも実績あり", traits: .sizeThatFitsLayout) {
    TodayContributionChartSection(contributions: [
        .init(userId: "user1", userName: "田中", completedCount: 3, point: 60),
        .init(userId: "user2", userName: "佐藤", completedCount: 1, point: 40),
    ])
}

#Preview("TodayContributionChartSection_実績0のメンバーあり", traits: .sizeThatFitsLayout) {
    TodayContributionChartSection(contributions: [
        .init(userId: "user1", userName: "田中", completedCount: 2, point: 50),
        .init(userId: "user2", userName: "佐藤", completedCount: 0, point: 0),
        .init(userId: "user3", userName: "鈴木", completedCount: 1, point: 10),
    ])
}
