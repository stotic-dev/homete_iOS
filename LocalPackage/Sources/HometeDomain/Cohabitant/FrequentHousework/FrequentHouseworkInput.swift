//
//  FrequentHouseworkInput.swift
//  LocalPackage
//

/// いつもの家事の追加・編集で入力する内容
public struct FrequentHouseworkInput: Equatable, Sendable {

    public let title: String
    public let point: Int
    /// カテゴリID。「その他（未設定）」は`nil`
    public let categoryId: String?

    public init(title: String, point: Int, categoryId: String?) {
        self.title = title
        self.point = point
        self.categoryId = categoryId
    }

}
