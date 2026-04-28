//
//  SummaryRow.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/28.
//

import HometeUI
import SwiftUI

struct SummaryRow: View {

    let item: ContributionRankItem

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
            VStack(alignment: .trailing, spacing: .space8) {
                HStack(spacing: .space4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("\(item.monthlyPoint)pt")
                        .font(with: .headLineM)
                        .foregroundStyle(.onSurface)
                }
                HStack(spacing: .space4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("\(item.achievedCount)件達成")
                        .font(with: .headLineM)
                        .foregroundStyle(.onSurface)
                }
            }
        }
        .padding(.horizontal, .space16)
        .padding(.vertical, .space16)
    }

    private var rankColor: Color {
        switch item.rank {
        case 1: .yellow
        case 2: Color(white: 0.7)
        case 3: Color(red: 0.8, green: 0.5, blue: 0.2)
        default: .secondary
        }
    }
}
