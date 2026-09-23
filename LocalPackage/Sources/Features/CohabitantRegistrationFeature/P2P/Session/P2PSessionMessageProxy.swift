//
//  P2PSessionMessageProxy.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/30.
//

import HometeDomain
import MultipeerConnectivity
import SwiftUI

/// P2Pセッションへ登録メッセージを送る口
/// - Note: セッションは`P2PSession`が張った後に決まるため、張れてから生成して`Store`へ渡す
@MainActor
final class P2PSessionMessageProxy {

    private let session: MCSession

    init(session: MCSession) {
        self.session = session
    }

}

extension P2PSessionMessageProxy: CohabitantRegistrationMessageSender {

    /// 登録メッセージを送信する
    /// - Note: 宛先は`displayName`で表されるため、接続中の`MCPeerID`から同じ名前のものを引き当てる。
    ///         送信に失敗した接続は続行できないため切断し、画面へ伝えられるようエラーは投げ直す
    func send(_ message: CohabitantRegistrationMessage, to peers: Set<CohabitantRegistrationPeerID>) throws {
        let targets = session.connectedPeers.filter { peers.contains(.init(displayName: $0.displayName)) }
        // 相手が切断済みで宛先が残っていない場合は、接続の変化を検知する側で扱うため送信しない
        guard !targets.isEmpty else { return }

        do {
            try session.send(message.encodedData(), toPeers: targets, with: .reliable)
            print("sent \(message.type) to: \(targets.map(\.displayName))")
        } catch {
            print("Failed send message to: \(targets.map(\.displayName)), error: \(error)")
            session.disconnect()
            throw error
        }
    }

}

extension EnvironmentValues {

    @Entry var p2pSessionProxy: P2PSessionMessageProxy?

}
