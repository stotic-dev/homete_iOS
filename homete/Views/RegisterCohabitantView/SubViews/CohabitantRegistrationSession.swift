//
//  CohabitantRegistrationSession.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/27.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationSession: View {
    
    @Environment(AccountStore.self) var accountStore
    
    @State var viewState = CohabitantRegistrationViewState.scanning
        
    var body: some View {
        ZStack {
            switch viewState {
            case .scanning:
                P2PScanner(serviceType: .register) {
                    CohabitantRegistrationSearchingStateView(
                        registrationState: $viewState,
                        scannerController: $0
                    )
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
    }
}
