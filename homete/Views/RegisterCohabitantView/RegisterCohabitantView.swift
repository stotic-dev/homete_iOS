//
//  RegisterCohabitantView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

struct RegisterCohabitantView: View {
    
    @Environment(AccountStore.self) var accountStore
    @Environment(\.appDependencies.appStorage) var appStorage
    @State var cohabitantRegistrationDataStore: CohabitantRegistrationDataStore?
    @State var isConnecting = false
    
    var body: some View {
        VStack {
            if let cohabitantRegistrationDataStore {
                if isConnecting {
                    Text("Started")
                    ForEach(cohabitantRegistrationDataStore.cohabitantPeerIDs, id: \.self) { displayName in
                        Text(displayName)
                    }
                }
                else {
                    Text("Not Started")
                    Button("Start Loading") {
                        Task {
                            isConnecting = true
                            await cohabitantRegistrationDataStore.startLoading()
                        }
                    }
                }
                
            }
        }
        .padding(.horizontal, DesignSystem.Space.space16)
        .task {
            do {
                let currentPeerID = try await MCPeerIDFactoryUseCase.make(
                    appStore: appStorage(),
                    displayName: accountStore.account.displayName
                )
                cohabitantRegistrationDataStore = .init(
                    provider: P2PService(peerID: currentPeerID, serviceType: .register),
                    myPeerID: currentPeerID
                )
            }
            catch {
                
                fatalError("fail set store(error: \(error)).")
            }
        }
        .onDisappear {
            cohabitantRegistrationDataStore?.removeResources()
        }
    }
}

#Preview {
    RegisterCohabitantView()
}
