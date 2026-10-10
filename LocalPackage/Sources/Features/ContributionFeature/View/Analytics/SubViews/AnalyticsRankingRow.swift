//
//  AnalyticsRankingRow.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/08.
//

import HometeUI
import SwiftUI

struct AnalyticsRankingRow: View {

    let item: ContributionAnalyticsRankItem
    let criterion: ContributionAnalyticsRankingCriterion
    let averageDenominator: AverageDenominator

    var body: some View {
        HStack(spacing: .space16) {
            Image(systemName: "\(item.rank).circle.fill")
                .font(.title2)
                .foregroundStyle(rankColor)
            VStack(alignment: .leading, spacing: .space4) {
                Text(item.userName)
                    .font(with: .headLineS)
                    .foregroundStyle(.textPrimary)
                if item.isMe {
                    Text("あなた", bundle: #bundle)
                        .font(with: .caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: .space4) {
                Text(totalText)
                    .font(with: .headLineM)
                    .foregroundStyle(.textPrimary)
                Text(averageText)
                    .font(with: .caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var rankColor: Color {
        switch item.rank {
        case 1: .yellow
        case 2: Color(white: 0.7)
        case 3: Color(red: 0.8, green: 0.5, blue: 0.2)
        default: .secondary
        }
    }

    /// 単位の付け方・語順が言語で変わるため、数値と単位を1つの文言にする
    private var totalText: LocalizedStringResource {
        switch criterion {
        case .point: .localized("\(item.totalValue)pt")
        case .achievement: .localized("\(item.totalValue)件", comment: "達成した家事の数")
        }
    }

    private var averageText: LocalizedStringResource {
        let average = String(format: "%.1f", item.averageValue)
        return switch (criterion, averageDenominator) {
        case (.point, .day): .localized("\(average)pt / 日", comment: "1日あたりの平均ポイント")
        case (.point, .month): .localized("\(average)pt / 月", comment: "1か月あたりの平均ポイント")
        case (.achievement, .day): .localized("\(average)件 / 日", comment: "1日あたりに達成した家事の平均数")
        case (.achievement, .month): .localized("\(average)件 / 月", comment: "1か月あたりに達成した家事の平均数")
        }
    }

}

extension AnalyticsRankingRow {

    /// 平均を何あたりで出すか
    enum AverageDenominator {

        case day
        case month

    }

}

#if DEBUG
#Preview("AnalyticsRankingRow_1位_あなた", traits: .sizeThatFitsLayout) {
    AnalyticsRankingRow(
        item: .init(
            rank: 1,
            userId: "user1",
            userName: "田中",
            isMe: true,
            totalValue: 120,
            averageValue: 17.1
        ),
        criterion: .point,
        averageDenominator: .day
    )
    .setupEnvironmentForPreview()
}

#Preview("AnalyticsRankingRow_2位", traits: .sizeThatFitsLayout) {
    AnalyticsRankingRow(
        item: .init(
            rank: 2,
            userId: "user2",
            userName: "佐藤",
            isMe: false,
            totalValue: 40,
            averageValue: 5.7
        ),
        criterion: .point,
        averageDenominator: .day
    )
    .setupEnvironmentForPreview()
}

#Preview("AnalyticsRankingRow_達成数", traits: .sizeThatFitsLayout) {
    AnalyticsRankingRow(
        item: .init(
            rank: 1,
            userId: "user1",
            userName: "田中",
            isMe: false,
            totalValue: 24,
            averageValue: 2.0
        ),
        criterion: .achievement,
        averageDenominator: .month
    )
    .setupEnvironmentForPreview()
}
#endif
