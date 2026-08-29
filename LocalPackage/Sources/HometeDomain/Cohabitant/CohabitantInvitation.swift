//
//  CohabitantInvitation.swift
//  LocalPackage
//

import Foundation

/// 発行された同居人グループへの招待
public struct CohabitantInvitation: Equatable, Identifiable, Sendable {

    /// 招待トークン
    public let token: String

    public var id: String {
        token
    }

    /// 招待先のグループID
    public let cohabitantId: String
    /// 招待の有効期限
    public let expiresAt: Date

    public init(token: String, cohabitantId: String, expiresAt: Date) {
        self.token = token
        self.cohabitantId = cohabitantId
        self.expiresAt = expiresAt
    }

    /// 共有するURL
    public var url: URL? {
        CohabitantInvitationLink.url(token: token)
    }

}

public extension CohabitantInvitation {

    static let preview = CohabitantInvitation(
        token: "preview-token",
        cohabitantId: "preview-cohabitant-id",
        expiresAt: Date(timeIntervalSince1970: 0)
    )

}
