//
//  HouseworkEffortSelectionContent.swift
//  LocalPackage
//

import HometeDomain
import HometeResources
import HometeUI
import SwiftUI

/// 家事の頑張り度を選ぶセグメント
struct HouseworkEffortSelectionContent: View {

    let selection: HouseworkEffort
    /// 上乗せ前後のポイントの内訳。上乗せしないときは`nil`
    let pointBreakdown: String?
    let onSelect: (HouseworkEffort) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .space8) {
            Picker(
                .localized("頑張り度"),
                selection: .init(
                    get: { selection },
                    set: { onSelect($0) }
                )
            ) {
                ForEach(HouseworkEffort.allCases) { effort in
                    Text(effort.title).tag(effort)
                }
            }
            .pickerStyle(.segmented)
            if let pointBreakdown {
                Text(pointBreakdown)
                    .font(with: .caption)
                    .foregroundStyle(.onSurfaceVariant)
                    .monospacedDigit()
            }
        }
    }

}

#if DEBUG
#Preview("HouseworkEffortSelectionContent_ふつう", traits: .sizeThatFitsLayout) {
    HouseworkEffortSelectionContent(selection: .normal, pointBreakdown: nil, onSelect: { _ in })
        .padding()
}

#Preview("HouseworkEffortSelectionContent_がんばった", traits: .sizeThatFitsLayout) {
    HouseworkEffortSelectionContent(selection: .hard, pointBreakdown: "10pt → 12pt", onSelect: { _ in })
        .padding()
}

#Preview("HouseworkEffortSelectionContent_超頑張った", traits: .sizeThatFitsLayout) {
    HouseworkEffortSelectionContent(selection: .veryHard, pointBreakdown: "100pt → 150pt", onSelect: { _ in })
        .padding()
}
#endif
