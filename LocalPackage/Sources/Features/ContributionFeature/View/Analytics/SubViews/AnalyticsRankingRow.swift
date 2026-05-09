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
    let totalUnit: String
    let averageDenominatorUnit: String

    var body: some View {
        HStack(spacing: .space16) {
            Image(systemName: "\(item.rank).circle.fill")
                .font(.title2)
                .foregroundStyle(rankColor)
            VStack(alignment: .leading, spacing: .space4) {
                Text(item.userName)
                    .font(with: .headLineS)
                    .foregroundStyle(.onSurface)
                if item.isMe {
                    Text("あなた")
                        .font(with: .caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: .space4) {
                Text("\(item.totalValue)\(totalUnit)")
                    .font(with: .headLineM)
                    .foregroundStyle(.onSurface)
                Text("\(formattedAverage) / \(averageDenominatorUnit)")
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

    private var formattedAverage: String {
        String(format: "%.1f%@", item.averageValue, totalUnit)
    }
}

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
        totalUnit: "pt",
        averageDenominatorUnit: "日"
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
        totalUnit: "pt",
        averageDenominatorUnit: "日"
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
        totalUnit: "件",
        averageDenominatorUnit: "月"
    )
    .setupEnvironmentForPreview()
}
