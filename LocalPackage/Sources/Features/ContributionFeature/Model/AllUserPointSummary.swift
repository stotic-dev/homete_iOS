//
//  AllUserPointSummary.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/28.
//

import HometeDomain

/// 全ユーザーの月間家事貢献度集計
struct AllUserPointSummary: Equatable {

    let items: [UserPointSummary]

    init(items: [UserPointSummary] = []) {
        self.items = items
    }

    /// 達成された家事があるかどうかで、データの有無を判定
    var hasData: Bool {
        !items.allSatisfy { $0.achievedCount == 0 }
    }

}
