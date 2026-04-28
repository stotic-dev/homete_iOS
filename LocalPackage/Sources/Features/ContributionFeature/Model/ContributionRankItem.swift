//
//  ContributionRankItem.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/28.
//

import Foundation

struct ContributionRankItem: Identifiable, Equatable, Sendable {

    var id: String { userId }

    /// 順位（1始まり）
    let rank: Int
    /// ユーザーID
    let userId: String
    /// 表示名
    let userName: String
    /// 自分かどうか
    let isMe: Bool
    /// 月間獲得ポイント
    let monthlyPoint: Int
    /// 達成した家事件数
    let achievedCount: Int
}

