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
        VStack(spacing: DesignSystem.Space.space16) {
            Text("デバイスの名前を確認してください")
                .font(with: .headLineM)
            ForEach(connectedDeviceNameList, id: \.self) { displayName in
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
                cohabitantRegistrationDataStore.isConfirmedCohabitants = true
            } label: {
                Text("登録を開始する")
                    .frame(maxWidth: .infinity)
            }
            .subPrimaryButtonStyle(isDisabled: connectedDeviceNameList.isEmpty)
        }
        .padding(.horizontal, DesignSystem.Space.space16)
        .onChange(of: cohabitantRegistrationDataStore.isConfirmedCohabitants) { _, newValue in
            guard newValue else { return }
            isPresentedConfirmCohabitantsAlert = true
        }
        .alert("表示されているメンバーで登録を開始しますか？", isPresented: $isPresentedConfirmCohabitantsAlert) {
            Button("OK") {
                cohabitantRegistrationDataStore.register()
            }
        }
    }
}

#Preview {
    CohabitantRegistrationSearchingStateView(
        connectedDeviceNameList: [
            "Test",
            "Test2",
            "Test3"]
    )
    .environment(
        CohabitantRegistrationDataStore(
            provider: P2PServiceProviderMock(),
            myPeerID: .init(displayName: "preview")
        )
    )
}
