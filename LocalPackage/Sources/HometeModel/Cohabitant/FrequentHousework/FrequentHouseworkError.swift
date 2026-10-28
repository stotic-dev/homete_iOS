//
//  FrequentHouseworkError.swift
//  LocalPackage
//

public enum FrequentHouseworkError: Error, Equatable, Sendable {

    /// 名前が空
    case emptyTitle
    /// 同じ名前のいつもの家事がすでにある
    case duplicatedTitle
    /// カテゴリ名が空
    case emptyCategoryName
    /// 同じ名前のカテゴリがすでにある（プリセット・「その他」を含む）
    case duplicatedCategoryName
    /// 無料プランの上限を超える
    case limitExceeded

}
