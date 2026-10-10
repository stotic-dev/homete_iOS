//
//  ContributionAnalyticsRankingCriterion.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/08.
//

import Foundation
import HometeDomain

enum ContributionAnalyticsRankingCriterion: String, CaseIterable, Identifiable {

    /// 獲得ポイント
    case point
    /// 家事達成数
    case achievement

    var id: String {
        rawValue
    }

    var title: LocalizedStringResource {
        switch self {
        case .point: .localized("ポイント")
        case .achievement: .localized("達成数")
        }
    }

    var totalUnit: LocalizedStringResource {
        switch self {
        case .point: "pt"
        case .achievement: .localized("件", comment: "家事を達成した数の単位。数値の直後に空白なしで付く（例: 24件）")
        }
    }

}
