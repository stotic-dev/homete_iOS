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
    @State var myPeerID: MCPeerID?
    @State var viewState = CohabitantRegistrationViewState.scanning
    
    var body: some View {
        ZStack {
            if let myPeerID {
                P2PSession(myPeerID: myPeerID) {
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
            }
        }
        .padding(.horizontal, DesignSystem.Space.space16)
        .task {
            do {
                myPeerID = try await MCPeerIDFactoryUseCase.make(
                    appStore: appStorage(),
                    displayName: accountStore.account.displayName
                )
            }
            catch {
                
                fatalError("fail set store(error: \(error)).")
            }
        }
    }
}

#Preview {
    CohabitantRegistrationView()
}
