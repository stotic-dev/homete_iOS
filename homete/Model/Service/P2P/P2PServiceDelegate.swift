//
//  P2PServiceDelegate.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/16.
//

import MultipeerConnectivity

protocol P2PServiceDelegate: AnyObject {
    
    /// 検索中にデバイスを発見したことを通知
    /// - Parameter peerID: 発見したデバイスの識別ID
    func didFoundDevice(peerID: MCPeerID)
    
    /// 検索中に発見していたデバイスを見失ったことを通知
    /// - Parameter peerID: 見失ったデバイスの識別ID
    func didLostDevice(peerID: MCPeerID)
    
    /// 発見したデバイスと接続するかどうかを判定する
    /// - Parameter peerID: 接続の招待をしたデバイスの識別ID
    /// - Returns: 接続するかどうか
    func shouldAcceptInvitation(from peerID: MCPeerID) -> Bool
    
    /// デバイスと接続したときの通知
    /// - Parameter peerID: 接続先の識別ID
    func didConnect(to peerID: MCPeerID)
    
    /// 接続していたデバイスと切断したことを通知
    /// - Parameter peerID: 切断したデバイスの識別ID
    func didDisconnect(from peerID: MCPeerID)
    
    /// データを受信したことを通知
    /// - Parameters:
    ///   - data: 受信したデータ
    ///   - peerID: 送信元のデバイスを識別するID
    func didReceiveData(_ data: Data, from peerID: MCPeerID)
    
    /// エラーが発生したことを通知
    func didReceiveError(_ error: any Error)
}
