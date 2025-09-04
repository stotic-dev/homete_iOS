//
//  NotRegisteredContent.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/04.
//

import SwiftUI

struct NotRegisteredContent: View {
    
    @State var isShowCohabitantRegistrationModal = false
    
    var body: some View {
        VStack(spacing: .zero) {
            Spacer()
                .frame(height: DesignSystem.Space.space24)
            VStack(spacing: DesignSystem.Space.space24) {
                Image(.suggestPartner)
                    .resizable()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(.radius16)
                VStack(spacing: DesignSystem.Space.space8) {
                    Text("まだパートナーが登録されていません")
                        .font(with: .headLineS)
                    Text("パートナーを登録して、家事を分担しましょう！")
                        .font(with: .body)
                }
                Button("パートナーを登録する") {
                    isShowCohabitantRegistrationModal = true
                }
                .primaryButtonStyle()
                Spacer()
            }
        }
        .padding(.horizontal, DesignSystem.Space.space16)
        .fullScreenCover(isPresented: $isShowCohabitantRegistrationModal) {
            CohabitantRegistrationView()
        }
    }
}

#Preview {
    NotRegisteredContent()
}
