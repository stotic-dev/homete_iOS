//
//  AllUserPointSummary.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/28.
//

import HometeDomain

/// 全ユーザーの月間家事貢献度集計
struct AllUserPointSummary: Equatable, Sendable {

    let items: [UserPointSummary]

    init(items: [UserPointSummary] = []) {
        self.items = items
    }
    
    /// 達成された家事があるかどうかで、データの有無を判定
    var hasData: Bool { !items.allSatisfy { $0.achievedCount == 0 } }

    /// ランキング形式のアイテム一覧を生成する
    func makeRanking() -> [ContributionRankItem] {
        items.sorted { $0.monthlyPoint.value > $1.monthlyPoint.value }
            .enumerated()
            .map { index, item in
                ContributionRankItem(
                    rank: index + 1,
                    userId: item.userId,
                    userName: item.userName,
                    isMe: item.isMe,
                    monthlyPoint: item.monthlyPoint,
                    achievedCount: item.achievedCount
                )
            }
    }
}
