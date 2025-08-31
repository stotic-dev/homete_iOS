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
    @Environment(\.rootNavigationPath) var rootNavigationPath
    
    var body: some View {
        P2PSession(displayName: accountStore.account.displayName) {
            CohabitantRegistrationSession(session: $0)
        }
    }
}
