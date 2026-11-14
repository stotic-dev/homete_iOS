//
//  TodayMemberContribution.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/09/26.
//

/// 当日のメンバー1人分の家事実績
public struct TodayMemberContribution: Equatable, Sendable, Identifiable {

    public let userId: String
    public let userName: String
    /// 今日完了した家事の数
    public let completedCount: Int
    /// 今日完了した家事で獲得したポイント
    public let point: Int

    public var id: String {
        userId
    }

    public init(userId: String, userName: String, completedCount: Int, point: Int) {
        self.userId = userId
        self.userName = userName
        self.completedCount = completedCount
        self.point = point
    }

}
