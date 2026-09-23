//
//  CohabitantRegistrationMessageSender.swift
//  LocalPackage
//

/// P2Pセッションへメッセージを送る口
/// - Note: セッションは画面ごとに張られ`AppDependencies`には載らないため、Storeへ直接注入する。
///         実装はFeature側（MultipeerConnectivity）が担う
@MainActor
public protocol CohabitantRegistrationMessageSender {

    /// メッセージを送信する
    /// - Note: 送信に失敗した場合はエラーを投げる。呼び出し側は`CohabitantRegistrationEvent.sendFailed`として扱う
    func send(_ message: CohabitantRegistrationMessage, to peers: Set<CohabitantRegistrationPeerID>) throws

}
