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
    @Environment(\.appDependencies.appStorage) var appStorage
    @Environment(\.rootNavigationPath) var rootNavigationPath
    @State var viewState = CohabitantRegistrationViewState.scanning
    
    var body: some View {
        P2PSession(displayName: accountStore.account.displayName) {
            switch viewState {
            case .scanning:
                P2PScanner(serviceType: .register) {
                    CohabitantRegistrationSearchingStateView(
                        registrationState: $viewState,
                        scannerController: $0
                    )
                }
            case .processing:
                CohabitantRegistrationInitialStateView()
            case .completed:
                CohabitantRegistrationCompleteView()
            }
        }
        .padding(.horizontal, DesignSystem.Space.space16)
    }
}

#Preview {
    CohabitantRegistrationView()
}
