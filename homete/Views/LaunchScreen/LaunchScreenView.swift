//
//  LaunchScreenView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/02.
//

import SwiftUI

struct LaunchScreenView: View {
    
    var body: some View {
        VStack(spacing: .space16) {
            Text("Homete")
                .font(with: .headLineL)
            Image(.launchScreenIcon)
                .resizable()
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(.radius8)
            Spacer()
        }
        .padding(.horizontal, .space16)
        .padding(.vertical, .space24)
    }
}

#Preview {
    LaunchScreenView()
}
