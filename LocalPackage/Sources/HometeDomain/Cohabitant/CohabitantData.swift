//
//  CohabitantData.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/01/04.
//

public struct CohabitantData: Codable, Sendable {

    public static let idField = "id"

    /// 家族グループのID
    public let id: String
    /// 参加しているメンバーのユーザーID
    public let members: [String]

    public init(id: String, members: [String]) {
        self.id = id
        self.members = members
    }
}
