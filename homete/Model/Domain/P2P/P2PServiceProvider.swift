//
//  P2PServiceProvider.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/12.
//

import MultipeerConnectivity
import Foundation

protocol P2PServiceProvider {
    
    var delegate: (any P2PServiceDelegate)? { get set }
    
    /// P2P通信のためにデバイスの検索を開始する
    func startSearching()
    
    /// P2P通信のすべてのリソースを削除
    func finish()
    
    /// セッションに参加しているデバイスのうち指定したデバイスにデータを送信する
    func send(_ data: Data, to peerID: [MCPeerID]) async
    
    /// 指定のデバイスとの接続を切断する
    func disconnect(to peerIDs: [MCPeerID])
    
    /// デバイスの探索を終了する
    func finishSearching()
}

final class P2PServiceProviderMock: P2PServiceProvider {
    
    var delegate: (any P2PServiceDelegate)?
    func startSearching() {}
    func finish() {}
    func send(_ data: Data, to peerID: [MCPeerID]) async {}
    func disconnect(to peerIDs: [MCPeerID]) {}
    func finishSearching() {}
}
