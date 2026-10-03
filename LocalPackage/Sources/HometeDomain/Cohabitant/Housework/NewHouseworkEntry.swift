//
//  NewHouseworkEntry.swift
//  LocalPackage
//

/// まとめて登録する家事1件
/// - Note: 入力元は家事のデータには残さず、Analyticsの`source`にだけ使う
public struct NewHouseworkEntry: Equatable, Sendable {

    public let item: HouseworkItem
    public let source: HouseworkRegisterSource

    public init(item: HouseworkItem, source: HouseworkRegisterSource) {
        self.item = item
        self.source = source
    }

    /// 入力したメモが上限を超えていないか検査する
    /// - Note: いつもの家事から選んだ家事のメモは、いつもの家事に保存したときに検査済みで、書いた人のプランで
    ///         上限が決まっているため検査しない（ADR-0033）
    /// - Throws: 上限を超えている場合は`HouseworkMemoError.limitExceeded`
    public func validateMemo(limitPolicy: HouseworkMemoLimitPolicy) throws {
        guard source == .manual else { return }
        try limitPolicy.validate(item.memo, original: nil)
    }

}
