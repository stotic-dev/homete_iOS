//
//  LegendPopover.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/28.
//

import SwiftUI

struct LegendPopover: View {

    var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            HStack(spacing: .space8) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("今月の獲得ポイント合計")
                    .font(with: .body)
            }
            HStack(spacing: .space8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("達成した家事の件数")
                    .font(with: .body)
            }
        }
        .padding(.space16)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    LegendPopover()
}
