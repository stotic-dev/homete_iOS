//
//  CohabitantMember.swift
//  homete
//
//  Created by 佐藤汰一 on 2026/01/04.
//

public struct CohabitantMember: Equatable, Hashable, Sendable {

    /// メンバーのユーザーID
    public let id: String
    /// メンバーのユーザー名
    public let userName: String

    public init(id: String, userName: String) {
        self.id = id
        self.userName = userName
    }
}
