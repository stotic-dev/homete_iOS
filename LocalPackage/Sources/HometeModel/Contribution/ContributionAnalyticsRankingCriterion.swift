//
//  ContributionAnalyticsRankingCriterion.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/08.
//

import Foundation

public enum ContributionAnalyticsRankingCriterion: String, CaseIterable, Identifiable, Sendable {

    /// 獲得ポイント
    case point
    /// 家事達成数
    case achievement

    public var id: String {
        rawValue
    }

    public var title: LocalizedStringResource {
        switch self {
        case .point: .localized("ポイント")
        case .achievement: .localized("達成数")
        }
    }

}
