//
//  FrequentHouseworkLimitStatus.swift
//  LocalPackage
//

/// 無料プランで表示する、登録件数と上限
struct FrequentHouseworkLimitStatus: Equatable {

    let count: Int
    let limit: Int

    /// 上限に達しているか
    var isReached: Bool {
        count >= limit
    }

}
