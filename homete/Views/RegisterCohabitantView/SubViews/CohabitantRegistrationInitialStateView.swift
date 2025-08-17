//
//  CohabitantRegistrationInitialStateView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationInitialStateView: View {
    
    var cohabitantRegistrationDataStore: CohabitantRegistrationDataStore
    
    var body: some View {
        VStack {
            Text("Not Started")
            Button("Start Loading") {
                Task {
                    await cohabitantRegistrationDataStore.startLoading()
                }
            }
        }
    }
}

#Preview {
    CohabitantRegistrationInitialStateView(
        cohabitantRegistrationDataStore: .init(
            provider: P2PServiceProviderMock(),
            myPeerID: .init()
        )
    )
}
