//
//  CohabitantRegistrationCompleteView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/20.
//

import SwiftUI

struct CohabitantRegistrationCompleteView: View {

    @State var isCracked = false
    
    var body: some View {
        ZStack {
            if isCracked {
                ConfettiRainView()
            }
            else {
                CrackerView {
                    withAnimation {
                        isCracked = true
                    }
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    CohabitantRegistrationCompleteView()
}
