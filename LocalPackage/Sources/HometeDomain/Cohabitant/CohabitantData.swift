//
//  CohabitantData.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/01/04.
//

public struct CohabitantData: Codable, Sendable {

    /// 家族グループのID
    /// - Note: ドキュメントIDと同じ値を持つ。Cloud Functions が `where("id", "==", ...)` で引くため、
    ///         FirestoreのセキュリティルールでもドキュメントIDとの一致を必須にしている。
    public let id: String
    /// 参加しているメンバーのユーザーID
    public let members: [String]

    public init(id: String, members: [String]) {
        self.id = id
        self.members = members
    }

}
