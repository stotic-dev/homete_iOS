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
    @Environment(\.rootNavigationPath) var rootNavigationPath
    @State var cohabitantRegistrationDataStore: CohabitantRegistrationDataStore?
    @State var isPresentedFailedRegisterAlert: Bool = false
    
    var body: some View {
        ZStack {
            if let cohabitantRegistrationDataStore {
                @Bindable var cohabitantRegistrationDataStore = cohabitantRegistrationDataStore
                ZStack {
                    switch cohabitantRegistrationDataStore.state {
                    case .initial:
                        CohabitantRegistrationInitialStateView(
                            cohabitantRegistrationDataStore: cohabitantRegistrationDataStore
                        )
                        
                    case .searching(let connectedDeviceNameList):
                        CohabitantRegistrationSearchingStateView(
                            cohabitantRegistrationDataStore: cohabitantRegistrationDataStore,
                            connectedDeviceNameList: connectedDeviceNameList
                        )
                        
                    case .registering:
                        CohabitantRegistrationRegisteringStateView()
                        
                    case .completed:
                        Text("登録完了")
                    }
                }
                .alert("登録に失敗しました", isPresented: $cohabitantRegistrationDataStore.hasError) {
                    Button("OK") {
                        rootNavigationPath.pop()
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
