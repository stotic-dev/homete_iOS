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

    /// 招待リンクと一緒に送る文言
    ///
    /// 複数の導線（同居人登録画面・設定画面）から同じ招待を共有するため、
    /// 文言が食い違わないようここに置く。
    static let shareMessage = "homeauで一緒に家事を管理しませんか？下のリンクから参加できます。"

    static let preview = CohabitantInvitation(
        token: "preview-token",
        cohabitantId: "preview-cohabitant-id",
        expiresAt: Date(timeIntervalSince1970: 0)
    )

}
