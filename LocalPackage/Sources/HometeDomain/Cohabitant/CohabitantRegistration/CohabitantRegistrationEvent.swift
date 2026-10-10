//
//  CohabitantRegistrationEvent.swift
//  LocalPackage
//

/// P2Pでの同居人登録の状態を進める入力
/// - Note: 画面操作・P2Pセッションの変化・非同期処理の結果をすべてこの型に揃え、
///         `CohabitantRegistrationStateMachine`へ流す
public enum CohabitantRegistrationEvent: Equatable, Sendable {

    public typealias PeerID = CohabitantRegistrationPeerID

    // MARK: P2Pセッション

    /// 接続中のメンバーが変わった
    case peersChanged(Set<PeerID>)
    /// メッセージを受信した
    case received(CohabitantRegistrationMessage, from: PeerID)
    /// メッセージの送信に失敗した
    /// - Note: 送信失敗時はセッションが切断されるため、続けて`peersChanged`が届く
    case sendFailed

    // MARK: 画面操作

    /// 表示中のメンバーで登録を開始するかどうかを確定した
    case userConfirmedMembers(isOK: Bool)
    /// アラートを閉じた
    case userDismissedAlert
    /// 役割の通知を再送するタイミング（登録処理中に定期的に届く）
    case tick

    // MARK: 非同期処理の結果

    /// 招待トークンの発行が完了した
    case invitationIssued(token: String)
    /// 招待トークンの発行に失敗した
    case invitationIssueFailed
    /// 同居人グループへの参加が自分のアカウントに反映された
    case cohabitantJoined
    /// 同居人グループへの参加、または参加結果の反映に失敗した
    case cohabitantJoinFailed

}
