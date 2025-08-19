//
//  CohabitantRegistrationSearchingStateView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationSearchingStateView: View {
    
    @Environment(CohabitantRegistrationDataStore.self) var cohabitantRegistrationDataStore
    @State var isPresentedConfirmCohabitantsAlert = false
    var connectedDeviceNameList: [String]
    
    var body: some View {
        VStack {
            Text("検索中")
            if !connectedDeviceNameList.isEmpty {
                Button("登録開始") {
                    cohabitantRegistrationDataStore.isConfirmedCohabitants = true
                }
            }
            ForEach(connectedDeviceNameList, id: \.self) { displayName in
                Text(displayName)
            }
        }
        .onChange(of: cohabitantRegistrationDataStore.isConfirmedCohabitants) { _, newValue in
            guard newValue else { return }
            isPresentedConfirmCohabitantsAlert = true
        }
        .alert("以下メンバーで登録を開始しますか？", isPresented: $isPresentedConfirmCohabitantsAlert) {
            Button("OK") {
                cohabitantRegistrationDataStore.register()
            }
        } message: {
            ForEach(connectedDeviceNameList, id: \.self) {
                Text($0)
            }
        }
    }
}

#Preview {
    CohabitantRegistrationSearchingStateView(connectedDeviceNameList: ["Test"])
}
