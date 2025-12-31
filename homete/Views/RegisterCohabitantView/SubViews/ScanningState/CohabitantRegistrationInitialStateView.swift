//
//  CohabitantRegistrationInitialStateView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

import SwiftUI

struct CohabitantRegistrationInitialStateView: View {
        
    var body: some View {
        VStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: .space16) {
                Text("同居人の登録")
                    .font(with: .headLineL)
                Text("同居人同士でこの画面を開いて近づけてください。自動的に登録が始まります。")
                    .font(with: .body)
            }
            Spacer()
                .frame(height: .space24)
            Image(.cohabitantsRegistrationGuide)
                .resizable()
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(.radius8)
            Spacer()
                .frame(height: .space16)
        }
        .padding(.horizontal, .space16)
    }
}

#Preview {
    CohabitantRegistrationInitialStateView()
}
