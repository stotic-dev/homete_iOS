//
//  FrequentHouseworkLimitPolicy.swift
//  LocalPackage
//

/// プランごとのいつもの家事の件数上限
/// - Note: 判定には操作している本人のプランを使う（プレミアムはアカウント単位で、グループ単位の概念がないため）。
///         `Account.isPremium`はクライアント書き込みのため、セキュリティルールでは検証しない
public enum FrequentHouseworkLimitPolicy: Equatable, Sendable {

    /// 無料プラン
    case free
    /// プレミアムプラン
    case premium

    /// 無料プランで登録できる件数（同居人グループ全体）
    public static let freeLimit = 10

    public init(isPremium: Bool) {
        self = isPremium ? .premium : .free
    }

    /// 登録できる件数の上限。無制限の場合は`nil`
    public var limit: Int? {
        switch self {
        case .free:
            Self.freeLimit

        case .premium:
            nil
        }
    }

    /// あと何件追加できるか。無制限の場合は`nil`
    public func remainingCount(currentCount: Int) -> Int? {
        limit.map { max($0 - currentCount, 0) }
    }

    /// `count`件を追加できるか
    public func canAdd(_ count: Int, currentCount: Int) -> Bool {
        guard let limit else { return true }
        return currentCount + count <= limit
    }

    /// 上限に達していて、これ以上追加できないか
    public func isLimitReached(currentCount: Int) -> Bool {
        !canAdd(1, currentCount: currentCount)
    }

    /// 上限を超えていて使えない家事のID
    /// - Note: プレミアムから無料に戻った場合に、表示順で上限より後ろの家事を使えなくする
    public func unusableItemIds(in context: FrequentHouseworkContext) -> Set<String> {
        guard let limit else { return [] }
        return Set(context.orderedItems.dropFirst(limit).map(\.id))
    }

}
