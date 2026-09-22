//
//  CohabitantRegistrationSession.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/27.
//

import HometeDomain
import HometeUI
import MultipeerConnectivity
import SwiftUI

struct CohabitantRegistrationSession: View {

    @Environment(\.dismiss) var dismiss
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
                .transition(.push(from: .trailing))
            case let .processing(isLead):
                ZStack {
                    if isLead {
                        CohabitantRegistrationProcessingLeader(
                            registrationState: $registrationState
                        )
                    } else {
                        CohabitantRegistrationProcessingFollower(
                            registrationState: $registrationState
                        )
                    }
                }
                .transition(.push(from: .trailing))
            case .completed:
                CohabitantCompletionView(
                    title: "登録が完了しました！",
                    message: "これからは、あなたとパートナーの家事を分担し、協力していくことができます。"
                ) {
                    dismiss()
                }
                .hideNavigationBar()
                .transition(.push(from: .trailing))
            }
        }
        .animation(.spring, value: registrationState)
    }

}
