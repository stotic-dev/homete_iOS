//
//  HouseworkEffort+Presentation.swift
//  LocalPackage
//

import HometeDomain

extension HouseworkEffort {

    var title: String {
        switch self {
        case .normal:
            "ふつう"

        case .hard:
            "がんばった"

        case .veryHard:
            "超頑張った"
        }
    }

    /// 上乗せ前後のポイントの内訳（例: `10pt → 12pt`）。上乗せしない「ふつう」では`nil`
    func pointBreakdown(basePoint: Int) -> String? {
        guard self != .normal else { return nil }

        return "\(basePoint)pt → \(boostedPoint(basePoint))pt"
    }

}
