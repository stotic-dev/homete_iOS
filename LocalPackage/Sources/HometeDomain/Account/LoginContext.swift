//
//  LoginContext.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/27.
//

public struct LoginContext: Equatable {

    public let account: Account
    /// 匿名認証のまま（Appleアカウントと未連携）かどうか
    public let isAnonymous: Bool

    /// パートナー登録済みかどうか
    public var hasCohabitant: Bool {
        account.cohabitantId != nil
    }

    /// 家族ID
    public var cohabitantId: String? {
        account.cohabitantId
    }

    /// Appleアカウントとの連携を終えるまで、ホームに入れない状態か
    /// - Note: 匿名のアカウントは機種変更・アンインストールで失われるため、グループに参加した状態で使わせない
    public var requiresAccountLink: Bool {
        isAnonymous && hasCohabitant
    }

    public init(account: Account, isAnonymous: Bool = false) {
        self.account = account
        self.isAnonymous = isAnonymous
    }

}
