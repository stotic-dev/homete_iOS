//
//  RegisterCohabitantView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/11.
//

import SwiftUI

struct RegisterCohabitantView: View {
    
    @Environment(AccountStore.self) var accountStore
    @State var cohabitantRegistrationDataStore: CohabitantRegistrationDataStore?
    @State var currentState: P2PSessionState = .initial

    var body: some View {
        Text("current state: \(currentState)")
    }
}

#Preview {
    RegisterCohabitantView(
        cohabitantRegistrationDataStore: .init(
            appDependencies: .previewValue,
            displayName: "TestName"
        )
    )
}
