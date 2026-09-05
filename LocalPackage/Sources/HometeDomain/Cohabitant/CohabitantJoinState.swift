//
//  CohabitantJoinState.swift
//  LocalPackage
//

/// 招待リンクからのグループ参加処理の状態
public enum CohabitantJoinState: Equatable, Sendable {

    /// 参加するかどうかの確認待ち
    case confirming
    /// 参加処理中
    case processing
    /// 参加完了
    case completed
    /// 参加できなかった
    case failed(CohabitantJoinFailure)

}

/// グループに参加できなかった理由
public enum CohabitantJoinFailure: Equatable, Sendable {

    /// 招待リンクが無効
    case invalidLink
    /// 招待リンクの有効期限切れ
    case expired
    /// すでに別のグループに参加している
    case alreadyJoined
    /// 通信エラーなど、上記以外の理由
    case unknown

}

extension CohabitantJoinFailure {

    init(_ error: any Error) {
        switch error {
        case CohabitantInvitationError.notFound:
            self = .invalidLink

        case CohabitantInvitationError.expired:
            self = .expired

        case CohabitantInvitationError.alreadyJoined:
            self = .alreadyJoined

        default:
            self = .unknown
        }
    }

}
