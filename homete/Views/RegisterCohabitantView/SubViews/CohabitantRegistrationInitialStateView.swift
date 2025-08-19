//
//  CohabitantRegistrationInitialStateView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

import SwiftUI

struct CohabitantRegistrationInitialStateView: View {
    
    @Environment(CohabitantRegistrationDataStore.self) var cohabitantRegistrationDataStore
    
    var body: some View {
        VStack {
            Text("Not Started")
                .task {
                    await cohabitantRegistrationDataStore.startLoading()
                }
        }
    }
}

#Preview {
    CohabitantRegistrationInitialStateView()
}
