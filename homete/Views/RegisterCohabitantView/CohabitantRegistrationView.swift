//
//  CohabitantRegistrationView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationView: View {
    
    @Environment(AccountStore.self) var accountStore
    @Environment(\.rootNavigationPath) var rootNavigationPath
    
    var body: some View {
        P2PSession(displayName: accountStore.account.displayName) {
            CohabitantRegistrationSession()
        }
        .padding(.horizontal, DesignSystem.Space.space16)
    }
}

struct CohabitantRegistrationSession: View {
    
    @Environment(AccountStore.self) var accountStore
    @Environment(\.p2pSessionReceiveDataStream) var receiveDataStream
    @State var viewState = CohabitantRegistrationViewState.scanning
    
    var body: some View {
        ZStack {
            switch viewState {
            case .scanning:
                P2PScanner(serviceType: .register) {
                    CohabitantRegistrationSearchingStateView(scannerController: $0)
                }
                .transition(.slide)
            case .processing:
                CohabitantRegistrationProcessingView(
                    myAccountId: accountStore.account.id,
                    isLeadDevice: true
                )
                .transition(.slide)
            case .completed:
                CohabitantRegistrationCompleteView()
                    .transition(
                        .asymmetric(insertion: .slide, removal: .scale)
                    )
            }
        }
        .task {
            for await receiveData in receiveDataStream {
                
            }
        }
    }
}
