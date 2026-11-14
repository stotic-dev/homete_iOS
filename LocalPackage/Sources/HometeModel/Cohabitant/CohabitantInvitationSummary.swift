//
//  CohabitantInvitationSummary.swift
//  LocalPackage
//

import Foundation

/// 参加前に表示する招待の概要
///
/// 参加確認画面で「〇〇さんのグループに参加しますか？」と表示するために、
/// 参加を実行する前にサーバーから取得する。
public struct CohabitantInvitationSummary: Equatable, Sendable {

    /// 招待者の表示名
    /// - Note: 招待者のアカウントが無い・名前未設定の場合はnil
    public let inviterName: String?
    /// 招待の有効期限
    public let expiresAt: Date

    public init(inviterName: String?, expiresAt: Date) {
        self.inviterName = inviterName
        self.expiresAt = expiresAt
    }

}

public extension CohabitantInvitationSummary {

    static let preview = CohabitantInvitationSummary(
        inviterName: "たろう",
        expiresAt: Date(timeIntervalSince1970: 0)
    )

}
