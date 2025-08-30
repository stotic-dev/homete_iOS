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
    
    @State var registrationState = CohabitantRegistrationState.scanning
    
    let session: MCSession?
        
    var body: some View {
        ZStack {
            switch registrationState {
            case .scanning:
                P2PScanner(serviceType: .register, session: session) {
                    CohabitantRegistrationScanningStateView(
                        registrationState: $registrationState,
                        scannerController: $0
                    )
                }
                .transition(.slide)
            case .processing(let isLead):
                ZStack {
                    if isLead {
                        CohabitantRegistrationProcessingLeader(
                            registrationState: $registrationState
                        )
                    }
                    else {
                        CohabitantRegistrationProcessingFollower(
                            registrationState: $registrationState
                        )
                    }
                }
                .transition(.slide)
            case .completed:
                CohabitantRegistrationCompleteView()
                    .transition(
                        .asymmetric(insertion: .slide, removal: .scale)
                    )
            }
        }
        .animation(nil, value: registrationState)
    }
}
