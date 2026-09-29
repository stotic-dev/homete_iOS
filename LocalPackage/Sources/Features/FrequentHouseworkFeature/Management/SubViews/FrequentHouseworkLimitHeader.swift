//
//  FrequentHouseworkLimitHeader.swift
//  LocalPackage
//

import HometeUI
import SwiftUI

/// 無料プランで、登録件数と上限を増やす導線を表示する
struct FrequentHouseworkLimitHeader: View {

    let status: FrequentHouseworkLimitStatus
    let onTapUpgrade: () -> Void

    var body: some View {
        HStack(spacing: .space8) {
            VStack(alignment: .leading, spacing: .space4) {
                Text("無料プランでは\(status.limit)件まで登録できます")
                    .font(with: .caption)
                    .foregroundStyle(.onSurfaceVariant)
                Text("\(status.count) / \(status.limit)件")
                    .font(with: .headLineS)
                    .foregroundStyle(status.isReached ? Color.destructive : Color.onSurface)
            }
            Spacer()
            Button("上限を増やす") {
                onTapUpgrade()
            }
            .font(with: .headLineS)
            .foregroundStyle(.accent)
        }
    }

}

#if DEBUG
#Preview("FrequentHouseworkLimitHeader_上限未満", traits: .sizeThatFitsLayout) {
    FrequentHouseworkLimitHeader(status: .init(count: 7, limit: 10, isReached: false), onTapUpgrade: {})
        .padding()
}

#Preview("FrequentHouseworkLimitHeader_上限到達", traits: .sizeThatFitsLayout) {
    FrequentHouseworkLimitHeader(status: .init(count: 12, limit: 10, isReached: true), onTapUpgrade: {})
        .padding()
}
#endif
