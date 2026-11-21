//
//  ContributionAnalyticsRankItem.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/05/08.
//

public struct ContributionAnalyticsRankItem: Identifiable, Equatable, Sendable {

    public var id: String {
        userId
    }

    /// 順位（1始まり）
    public let rank: Int
    /// ユーザーID
    public let userId: String
    /// 表示名
    public let userName: String
    /// 自分かどうか
    public let isMe: Bool
    /// トータル値（criterionに応じてポイントまたは達成数）
    public let totalValue: Int
    /// 平均値（週・月の場合は1日あたり、年の場合は1ヶ月あたり）
    public let averageValue: Double

    public init(
        rank: Int,
        userId: String,
        userName: String,
        isMe: Bool,
        totalValue: Int,
        averageValue: Double
    ) {
        self.rank = rank
        self.userId = userId
        self.userName = userName
        self.isMe = isMe
        self.totalValue = totalValue
        self.averageValue = averageValue
    }

}
