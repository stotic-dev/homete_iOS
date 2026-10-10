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

}
