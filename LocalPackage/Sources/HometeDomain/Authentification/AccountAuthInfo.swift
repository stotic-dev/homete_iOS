//
//  AccountAuthInfo.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/31.
//

public struct AccountAuthInfo: Equatable, Sendable {
    public let result: AccountAuthResult?
    public let alreadyLoadedAtInitiate: Bool

    public static let initial = AccountAuthInfo(result: nil, alreadyLoadedAtInitiate: false)

    public init(result: AccountAuthResult?, alreadyLoadedAtInitiate: Bool) {
        self.result = result
        self.alreadyLoadedAtInitiate = alreadyLoadedAtInitiate
    }
}
