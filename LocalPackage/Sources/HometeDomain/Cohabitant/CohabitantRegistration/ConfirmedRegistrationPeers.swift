//
//  ConfirmedRegistrationPeers.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/30.
//

import MultipeerConnectivity

public struct ConfirmedRegistrationPeers: Equatable {

    private var peers: Set<MCPeerID>

    public init(peers: Set<MCPeerID>) {

        self.peers = peers
    }

    public mutating func addPeer(_ peer: MCPeerID) {

        peers.insert(peer)
    }

    public func isLeadPeer(connectedPeers: Set<MCPeerID>, myPeerID: MCPeerID) -> Bool? {

        guard peers == connectedPeers else { return nil }
        let firstPeerID = ([myPeerID] + connectedPeers)
            .sorted { $0.displayName < $1.displayName }.first
        return firstPeerID == myPeerID
    }
}
