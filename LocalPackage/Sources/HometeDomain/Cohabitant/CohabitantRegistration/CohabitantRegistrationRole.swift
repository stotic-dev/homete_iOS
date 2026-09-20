//
//  CohabitantRegistrationRole.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/30.
//

public enum CohabitantRegistrationRole: Codable, Equatable, Sendable {

    /// フォロワーはアカウントIDを渡す
    case follower(accountId: String)
    case lead

    public var isLeader: Bool {
        self == .lead
    }

    /// フォロワーのアカウントID（リーダーはnil）
    public var accountId: String? {
        guard case let .follower(accountId) = self else { return nil }
        return accountId
    }

}
