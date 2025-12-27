//
//  CohabitantRegistrationCompleteView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/20.
//

import SwiftUI

struct CohabitantRegistrationCompleteView: View {

    @Environment(\.dismiss) var dismiss
    
    @State var isCracked = false
    
    var body: some View {
        ZStack {
            VStack(spacing: .space16) {
                Text("登録が完了しました！")
                    .font(with: .headLineL)
                Text("これからは、あなたとパートナーの家事を分担し、協力していくことができます。")
                    .font(with: .body)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("閉じる")
                        .frame(maxWidth: .infinity)
                }
                .subPrimaryButtonStyle()
            }
            .padding(.horizontal, .space16)
            .padding(.vertical, .space24)
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
        .automaticToolbarVisibility(visibility: .hidden, for: .navigationBar)
    }
}
