//
//  ContributionAnalyticsRankItem.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/08.
//

struct ContributionAnalyticsRankItem: Identifiable, Equatable, Sendable {

    var id: String { userId }

    /// 順位（1始まり）
    let rank: Int
    /// ユーザーID
    let userId: String
    /// 表示名
    let userName: String
    /// 自分かどうか
    let isMe: Bool
    /// トータル値（criterionに応じてポイントまたは達成数）
    let totalValue: Int
    /// 平均値（週・月の場合は1日あたり、年の場合は1ヶ月あたり）
    let averageValue: Double
}
