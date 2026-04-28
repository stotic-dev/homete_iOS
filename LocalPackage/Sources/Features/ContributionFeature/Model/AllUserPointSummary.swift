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

    /// ランキング形式のアイテム一覧を生成する
    func makeRanking(members: CohabitantMemberList, myUserId: String) -> [ContributionRankItem] {
        items.sorted { $0.monthlyPoint.value > $1.monthlyPoint.value }
            .enumerated().map { index, item in
                ContributionRankItem(
                    rank: index + 1,
                    userId: item.userId,
                    userName: members.userName(item.userId) ?? item.userId,
                    isMe: item.userId == myUserId,
                    monthlyPoint: item.monthlyPoint,
                    achievedCount: item.achievedCount
                )
            }
    }
}
