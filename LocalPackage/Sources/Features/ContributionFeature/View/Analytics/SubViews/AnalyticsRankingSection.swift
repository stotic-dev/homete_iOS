//
//  AnalyticsRankingSection.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/08.
//

import HometeUI
import SwiftUI

struct AnalyticsRankingSection: View {

    let pointRanking: [ContributionAnalyticsRankItem]
    let achievementRanking: [ContributionAnalyticsRankItem]
    let selectedPriodType: DisplayPointPeriod.PeriodType

    @State private var selectedCriterion: ContributionAnalyticsRankingCriterion = .point

    /// ランキング行の高さ
    private static let rowHeight: CGFloat = 70

    var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            Text("メンバー別ランキング")
                .font(with: .headLineS)
                .foregroundStyle(.onSurface)
                .padding(.horizontal, .space16)

            Picker("ランキング種別", selection: $selectedCriterion) {
                ForEach(ContributionAnalyticsRankingCriterion.allCases) { criterion in
                    Text(criterion.title).tag(criterion)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, .space16)

            #if os(iOS)
                TabView(selection: $selectedCriterion) {
                    rankingList(items: pointRanking, criterion: .point)
                        .tag(ContributionAnalyticsRankingCriterion.point)

                    rankingList(items: achievementRanking, criterion: .achievement)
                        .tag(ContributionAnalyticsRankingCriterion.achievement)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: tabViewHeight)
            #endif
        }
    }

}

private extension AnalyticsRankingSection {

    func rankingList(
        items: [ContributionAnalyticsRankItem],
        criterion: ContributionAnalyticsRankingCriterion
    ) -> some View {
        VStack(spacing: .zero) {
            ForEach(items) { item in
                AnalyticsRankingRow(
                    item: item,
                    totalUnit: criterion.totalUnit,
                    averageDenominatorUnit: averageDenominatorUnit
                )
                .padding(.horizontal, .space16)
                .padding(.vertical, .space16)
                .frame(height: Self.rowHeight)
                Divider()
                    .padding(.leading, .space16)
            }
        }
    }

    var tabViewHeight: CGFloat {
        let rowCount = max(pointRanking.count, achievementRanking.count, 1)
        return CGFloat(rowCount) * (Self.rowHeight + 1)
    }

    var averageDenominatorUnit: String {
        switch selectedPriodType {
        case .week, .month: "日"
        case .year: "月"
        }
    }

}

#if DEBUG
    #Preview("AnalyticsRankingSection_週", traits: .sizeThatFitsLayout) {
        AnalyticsRankingSection(
            pointRanking: [
                .init(rank: 1, userId: "user1", userName: "田中", isMe: true, totalValue: 78, averageValue: 11.1),
                .init(rank: 2, userId: "user2", userName: "佐藤", isMe: false, totalValue: 60, averageValue: 8.6),
                .init(rank: 3, userId: "user3", userName: "佐藤", isMe: false, totalValue: 50, averageValue: 8.2),
                .init(rank: 4, userId: "user4", userName: "佐藤", isMe: false, totalValue: 40, averageValue: 8.1),
            ],
            achievementRanking: [
                .init(rank: 1, userId: "user1", userName: "田中", isMe: true, totalValue: 5, averageValue: 0.7),
                .init(rank: 2, userId: "user2", userName: "佐藤", isMe: false, totalValue: 3, averageValue: 0.4),
                .init(rank: 3, userId: "user3", userName: "佐藤", isMe: false, totalValue: 50, averageValue: 8.2),
                .init(rank: 4, userId: "user4", userName: "佐藤", isMe: false, totalValue: 40, averageValue: 8.1),
            ],
            selectedPriodType: .week
        )
        .setupEnvironmentForPreview()
    }

    #Preview("AnalyticsRankingSection_年", traits: .sizeThatFitsLayout) {
        AnalyticsRankingSection(
            pointRanking: [
                .init(rank: 1, userId: "user2", userName: "佐藤", isMe: false, totalValue: 350, averageValue: 29.2),
                .init(rank: 2, userId: "user1", userName: "田中", isMe: true, totalValue: 280, averageValue: 23.3),
            ],
            achievementRanking: [
                .init(rank: 1, userId: "user1", userName: "田中", isMe: true, totalValue: 24, averageValue: 2.0),
                .init(rank: 2, userId: "user2", userName: "佐藤", isMe: false, totalValue: 18, averageValue: 1.5),
            ],
            selectedPriodType: .year
        )
        .setupEnvironmentForPreview()
    }
#endif
