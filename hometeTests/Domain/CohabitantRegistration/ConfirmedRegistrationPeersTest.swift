//
//  ConfirmedRegistrationPeersTest.swift
//  hometeTests
//
//  Created by 佐藤汰一 on 2025/08/31.
//

import MultipeerConnectivity
import Testing
@testable import homete

struct ConfirmedRegistrationPeersTest {

    @Test("PeerIDの表示名の降順で一番最初のPeerIDになるデバイスがリードデバイスになる")
    func isLeadPeer_lead_case() throws {
        
        let connectedPeers: Set<MCPeerID> = [
            .init(displayName: "BBB"),
            .init(displayName: "CCC"),
            .init(displayName: "EEE")
        ]
        let peers = ConfirmedRegistrationPeers(peers: connectedPeers)
        
        let actual = peers.isLeadPeer(
            connectedPeers: connectedPeers,
            myPeerID: .init(displayName: "AAA")
        )
        
        #expect(actual == true)
    }
    
    @Test(
        "PeerIDの表示名の降順で一番最初ではない場合は、フォロワーデバイスになる",
        arguments: [
            MCPeerID(displayName: "DDD"),
            .init(displayName: "FFF"),
            .init(displayName: "CCC"),
            .init(displayName: "ZZZ")
        ]
    )
    func isLeadPeer_follower_case(myPeerID: MCPeerID) throws {
        
        let connectedPeers: Set<MCPeerID> = [
            .init(displayName: "BBB"),
            .init(displayName: "CCC"),
            .init(displayName: "EEE")
        ]
        let peers = ConfirmedRegistrationPeers(peers: connectedPeers)
        
        let actual = peers.isLeadPeer(connectedPeers: connectedPeers, myPeerID: myPeerID)
        
        #expect(actual == false)
    }
    
    @Test(
        "接続中の全てのデバイスが確認済みでない場合は、まだ登録メンバーが揃っていないのでリードデバイスかどうかを返さない"
    )
    func isLeadPeer_not_match_case() throws {
        
        let confirmedPeers: Set<MCPeerID> = [
            .init(displayName: "BBB"),
            .init(displayName: "CCC")
        ]
        let connectedPeers: Set<MCPeerID> = .init(confirmedPeers + [.init(displayName: "EEE")])
        let peers = ConfirmedRegistrationPeers(peers: confirmedPeers)
        
        let actual = peers.isLeadPeer(connectedPeers: connectedPeers, myPeerID: .init(displayName: "AAA"))
        
        #expect(actual == nil)
    }
}
