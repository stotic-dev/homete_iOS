//
//  HouseworkEffort+Presentation.swift
//  LocalPackage
//

import Foundation
import HometeDomain

extension HouseworkEffort {

    var title: LocalizedStringResource {
        switch self {
        case .normal:
            .localized("ふつう")

        case .hard:
            .localized("がんばった")

        case .veryHard:
            .localized("すごくがんばった")
        }
    }

    /// 上乗せ前後のポイントの内訳（例: `10pt → 12pt`）。上乗せしない「ふつう」では`nil`
    func pointBreakdown(basePoint: Int) -> String? {
        guard self != .normal else { return nil }

        return "\(basePoint)pt → \(boostedPoint(basePoint))pt"
    }

}
