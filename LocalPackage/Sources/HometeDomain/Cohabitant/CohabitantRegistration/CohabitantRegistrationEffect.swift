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
    /// 同居人レコードを作成する
    case registerCohabitant(CohabitantData)
    /// 自分のアカウントに同居人IDを保存する
    case saveCohabitantId(String)
    /// Analyticsイベントを送る
    case log(CohabitantRegistrationAnalyticsAction)

}
