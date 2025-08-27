//
//  CohabitantRegistrationSearchingStateView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationSearchingStateView: View {
    
    @Environment(P2PConnectedPeersStore.self) var connectedPeersStore
    @Binding var registrationState: CohabitantRegistrationViewState
    let scannerController: any P2PScannerClient
    
    var body: some View {
        ZStack {
            if connectedPeersStore.peers.isEmpty {
                CohabitantRegistrationInitialStateView()
            }
            else {
                VStack(spacing: DesignSystem.Space.space16) {
                    Text("デバイスの名前を確認してください")
                        .font(with: .headLineM)
                    ForEach(convertToDisplayNameList(connectedPeersStore.peers), id: \.self) { displayName in
                        HStack(spacing: DesignSystem.Space.space24) {
                            Image(systemName: "iphone")
                                .frame(width: 24, height: 24)
                                .padding(DesignSystem.Space.space8)
                                .background(.primary3)
                                .cornerRadius(.radius8)
                            Text(displayName)
                                .font(with: .body)
                            Spacer()
                        }
                    }
                    Spacer()
                    Button {
                        registrationState = .processing
                    } label: {
                        Text("登録を開始する")
                            .frame(maxWidth: .infinity)
                    }
                    .subPrimaryButtonStyle()
                }
                .padding(.horizontal, DesignSystem.Space.space16)
            }
        }
        .onAppear {
            scannerController.startScan()
        }
        .onDisappear {
            scannerController.finishScan()
        }
    }
}

private extension CohabitantRegistrationSearchingStateView {
    
    func convertToDisplayNameList(_ peers: Set<MCPeerID>) -> [String] {
        
        return peers.compactMap {
            
            $0.displayName.components(separatedBy: "_").first
        }
    }
}

#Preview("デバイス未検知ケース") {
    @Previewable @State var registrationState = CohabitantRegistrationViewState.scanning
    CohabitantRegistrationSearchingStateView(
        registrationState: $registrationState,
        scannerController: P2PScannerClientMock(eventStream: .init { return .error })
    )
    .environment(P2PConnectedPeersStore())
}

#Preview("デバイス検知済みケース") {
    @Previewable @State var registrationState = CohabitantRegistrationViewState.scanning
    CohabitantRegistrationSearchingStateView(
        registrationState: $registrationState,
        scannerController: P2PScannerClientMock(eventStream: .init { return .error })
    )
    .environment(P2PConnectedPeersStore(peers: [.init(displayName: "Test_UUID")]))
}
