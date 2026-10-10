//
//  CohabitantRegistrationEffect.swift
//  LocalPackage
//

/// `CohabitantRegistrationStateMachine`が要求する外部I/O
/// - Note: 実行は`CohabitantRegistrationStore`が担い、結果は`CohabitantRegistrationEvent`として状態機械へ戻す
public enum CohabitantRegistrationEffect: Equatable, Sendable {

    public typealias PeerID = CohabitantRegistrationPeerID

    /// メッセージを送信する
    case send(CohabitantRegistrationMessage, to: Set<PeerID>)
    /// 招待トークンを発行する（リーダー）
    case issueInvitation
    /// 招待トークンを使って同居人グループに参加する（フォロワー）
    case joinCohabitant(invitationToken: String)
    /// サーバー側でグループIDが書き込まれた自分のアカウントを取り直す（リーダー）
    case reloadAccount
    /// Analyticsイベントを送る
    case log(CohabitantRegistrationAnalyticsAction)

}
