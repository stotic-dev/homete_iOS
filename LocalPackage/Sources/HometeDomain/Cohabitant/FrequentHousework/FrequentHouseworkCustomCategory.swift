//
//  FrequentHouseworkCustomCategory.swift
//  LocalPackage
//

import Foundation

/// ユーザーが追加したカテゴリ（同居人グループで共有する）
public struct FrequentHouseworkCustomCategory: Identifiable, Codable, Sendable, Equatable, Hashable {

    public let id: String
    public let name: String
    /// カスタムカテゴリ内の並び順
    public let sortOrder: Int
    public let createdAt: Date

    public init(id: String, name: String, sortOrder: Int, createdAt: Date) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }

}
