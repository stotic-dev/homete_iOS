//
//  FrequentHouseworkItem.swift
//  LocalPackage
//

import Foundation

/// いつもの家事1件
/// - Note: 単発登録・テンプレートから呼び出したときは中身をコピーするだけで、呼び出し先とは紐付けない（ADR-0020）
public struct FrequentHouseworkItem: Identifiable, Codable, Sendable, Equatable, Hashable {

    public let id: String
    /// 家事の名前
    public let title: String
    /// 家事ポイント
    public let point: Int
    /// カテゴリID（プリセットIDまたはカスタムカテゴリID）
    /// - Note: 未設定、または削除済みのカテゴリを指している場合は「その他」として扱う
    public let categoryId: String?
    /// カテゴリ内の並び順
    public let sortOrder: Int
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: String,
        title: String,
        point: Int,
        categoryId: String?,
        sortOrder: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.point = point
        self.categoryId = categoryId
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

}
