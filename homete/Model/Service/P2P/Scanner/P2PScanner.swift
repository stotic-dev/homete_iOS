//
//  P2PScanner.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/26.
//

import MultipeerConnectivity
import SwiftUI

struct P2PScanner<Content: View>: View {
    
    @Environment(\.myPeerID) var myPeerID
    @Environment(\.p2pSession) var session
    
    @State var controller: P2PScannerController?
    
    let serviceType: P2PServiceType
    let content: (any P2PScannerClient) -> Content
    
    init(
        serviceType: P2PServiceType,
        @ViewBuilder content: @escaping (any P2PScannerClient) -> Content
    ) {
        
        self.serviceType = serviceType
        self.content = content
    }
    
    var body: some View {
        ZStack {
            if let controller {
                content(controller)
            }
            else {
                EmptyView()
            }
        }
        .onChange(of: myPeerID) {
            setupController()
        }
        .onChange(of: session) {
            setupController()
        }
    }
}

private extension P2PScanner {
    
    func setupController() {
        
        guard let myPeerID,
              let session else { return }
        controller = .init(session: session, myPeerID: myPeerID, serviceType: serviceType)
    }
}
