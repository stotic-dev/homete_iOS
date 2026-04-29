//
//  UserPointSummary.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation
import HometeDomain

/// ユーザーの家事貢献度集計結果
struct UserPointSummary: Equatable, Sendable, Identifiable {

    var id: String { userId }

    /// ユーザーID
    let userId: String

    /// 表示名
    let userName: String

    /// 自分かどうか
    let isMe: Bool

    /// 月間獲得ポイント（当月に完了した家事の合計ポイント）
    let monthlyPoint: Point

    /// もらった感謝の数（自分が実行しレビューされて完了した家事の数）
    let achievedCount: Int
}
