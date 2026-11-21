//
//  UserPointSummary.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation

/// ユーザーの家事貢献度集計結果
public struct UserPointSummary: Equatable, Identifiable, Sendable {

    public var id: String {
        userId
    }

    /// ユーザーID
    public let userId: String

    /// 表示名
    public let userName: String

    /// 自分かどうか
    public let isMe: Bool

    /// 月間獲得ポイント（当月に完了した家事の合計ポイント）
    public let monthlyPoint: Point

    /// もらった感謝の数（自分が実行しレビューされて完了した家事の数）
    public let achievedCount: Int

    public init(
        userId: String,
        userName: String,
        isMe: Bool,
        monthlyPoint: Point,
        achievedCount: Int
    ) {
        self.userId = userId
        self.userName = userName
        self.isMe = isMe
        self.monthlyPoint = monthlyPoint
        self.achievedCount = achievedCount
    }

}
