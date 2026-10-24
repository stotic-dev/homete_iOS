//
//  AccountAuthResult.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/09.
//

public struct AccountAuthResult: Equatable, Sendable {

    public let id: String
    /// 匿名認証のまま（Appleアカウントと未連携）かどうか
    public let isAnonymous: Bool

    public init(id: String, isAnonymous: Bool = false) {
        self.id = id
        self.isAnonymous = isAnonymous
    }

}
