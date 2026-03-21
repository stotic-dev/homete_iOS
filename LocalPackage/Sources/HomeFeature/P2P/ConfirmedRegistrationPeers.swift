import MultipeerConnectivity

struct ConfirmedRegistrationPeers: Equatable {

    private var peers: Set<MCPeerID>

    init(peers: Set<MCPeerID>) {

        self.peers = peers
    }

    mutating func addPeer(_ peer: MCPeerID) {

        peers.insert(peer)
    }

    func isLeadPeer(connectedPeers: Set<MCPeerID>, myPeerID: MCPeerID) -> Bool? {

        guard peers == connectedPeers else { return nil }
        let firstPeerID = ([myPeerID] + connectedPeers)
            .sorted { $0.displayName < $1.displayName }.first
        return firstPeerID == myPeerID
    }
}
