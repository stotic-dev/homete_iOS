//
//  FrequentHouseworkLimitStatus.swift
//  LocalPackage
//

/// 無料プランで表示する、登録件数と上限
/// - Note: 上限に達しているかの判断は`FrequentHouseworkLimitPolicy`が持つ。
///         ここは表示する値だけを運ぶ（メンバーごとのイニシャライザはPreviewで表示のバリエーションを作るのに使う）
public struct FrequentHouseworkLimitStatus: Equatable, Sendable {

    public let count: Int
    public let limit: Int
    /// 上限に達しているか
    public let isReached: Bool

    public init(
        count: Int,
        limit: Int,
        isReached: Bool
    ) {
        self.count = count
        self.limit = limit
        self.isReached = isReached
    }

}

public extension FrequentHouseworkLimitStatus {

    /// プランと登録件数から作る
    /// - Returns: 上限のないプランでは`nil`
    init?(policy: FrequentHouseworkLimitPolicy, count: Int) {
        guard let limit = policy.limit else { return nil }
        self.init(count: count, limit: limit, isReached: policy.isLimitReached(currentCount: count))
    }

}
