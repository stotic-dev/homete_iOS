//
//  CohabitantRegistrationSearchingStateView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationSearchingStateView: View {
    
    var cohabitantRegistrationDataStore: CohabitantRegistrationDataStore
    var connectedDeviceNameList: [String]
    
    var body: some View {
        VStack {
            Text("検索中")
            if !connectedDeviceNameList.isEmpty {
                Button("登録開始") {
                    cohabitantRegistrationDataStore.register()
                }
            }
            ForEach(connectedDeviceNameList, id: \.self) { displayName in
                Text(displayName)
            }
        }
    }
}

#Preview {
    CohabitantRegistrationSearchingStateView(
        cohabitantRegistrationDataStore: .init(
            provider: P2PServiceProviderMock(),
            myPeerID: .init()
        ),
        connectedDeviceNameList: ["Test"]
    )
}
