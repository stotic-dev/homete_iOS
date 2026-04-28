//
//  SummaryRow.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/28.
//

import SwiftUI

struct SummaryRow: View {

    let userName: String
    let isMe: Bool
    let monthlyPoint: Int
    let achievedCount: Int

    var body: some View {
        HStack(spacing: .space16) {
            VStack(alignment: .leading, spacing: .space4) {
                Text(userName)
                    .font(with: .headLineS)
                    .foregroundStyle(.onSurface)
                if isMe {
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
                    Text("\(monthlyPoint)pt")
                        .font(with: .headLineM)
                        .foregroundStyle(.onSurface)
                }
                HStack(spacing: .space4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("\(achievedCount)件達成")
                        .font(with: .headLineM)
                        .foregroundStyle(.onSurface)
                }
            }
        }
        .padding(.horizontal, .space16)
        .padding(.vertical, .space16)
    }
}
