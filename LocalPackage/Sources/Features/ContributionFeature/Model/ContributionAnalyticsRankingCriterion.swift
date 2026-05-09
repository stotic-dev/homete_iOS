//
//  ContributionAnalyticsRankingCriterion.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/08.
//

enum ContributionAnalyticsRankingCriterion: String, CaseIterable, Identifiable, Sendable {
    /// 獲得ポイント
    case point
    /// 家事達成数
    case achievement

    var id: String { rawValue }

    var title: String {
        switch self {
        case .point: "ポイント"
        case .achievement: "達成数"
        }
    }

    var totalUnit: String {
        switch self {
        case .point: "pt"
        case .achievement: "件"
        }
    }
}
