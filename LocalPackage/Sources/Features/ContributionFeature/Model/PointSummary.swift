//
//  PointSummary.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/25.
//

import Foundation
import HometeDomain

/// ユーザーの家事貢献度集計結果
struct PointSummary: Equatable, Sendable, Identifiable {

    var id: String { userId }

    /// ユーザーID
    let userId: String

    /// 月間獲得ポイント（当月に完了した家事の合計ポイント）
    let monthlyPoint: Int

    /// もらった感謝の数（自分が実行しレビューされて完了した家事の数）
    let achievedCount: Int

    init(userId: String, monthlyPoint: Int, achievedCount: Int) {
        self.userId = userId
        self.monthlyPoint = monthlyPoint
        self.achievedCount = achievedCount
    }
}

extension PointSummary {

    /// HouseworkItemの配列から指定月のPointSummaryを算出する
    static func calculate(
        userId: String,
        from items: [HouseworkItem],
        in month: Date,
        calendar: Calendar
    ) -> PointSummary {

        let completedInMonth = items.filter { item in
            guard item.state == .completed,
                  let approvedAt = item.approvedAt else { return false }
            return calendar.isDate(approvedAt, equalTo: month, toGranularity: .month)
        }

        let monthlyPoint = completedInMonth
            .filter { $0.executorId == userId }
            .reduce(0) { $0 + $1.point }

        let achievedCount = completedInMonth
            .filter { $0.executorId == userId && $0.reviewerId != nil }
            .count

        return PointSummary(
            userId: userId,
            monthlyPoint: monthlyPoint,
            achievedCount: achievedCount
        )
    }
}
