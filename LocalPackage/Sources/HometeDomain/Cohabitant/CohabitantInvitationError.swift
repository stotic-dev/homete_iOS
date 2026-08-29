//
//  CohabitantInvitationError.swift
//  LocalPackage
//

/// 招待リンクによるグループ参加で発生するエラー
public enum CohabitantInvitationError: Error, Equatable, Sendable {

    /// 招待が見つからない（無効なリンク）
    case notFound
    /// 招待の有効期限が切れている
    case expired
    /// すでに別のグループに参加している
    case alreadyJoined

}
