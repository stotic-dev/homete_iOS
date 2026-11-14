//
//  AllUserPointSummary.swift
//  LocalPackage
//
//  Created by Taichi Sato on 2026/04/28.
//

/// 全ユーザーの月間家事貢献度集計
public struct AllUserPointSummary: Equatable, Sendable {

    public let items: [UserPointSummary]

    public init(items: [UserPointSummary] = []) {
        self.items = items
    }

    /// 達成された家事があるかどうかで、データの有無を判定
    public var hasData: Bool {
        !items.allSatisfy { $0.achievedCount == 0 }
    }

}
