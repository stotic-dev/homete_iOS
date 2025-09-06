//
//  RegisterHouseworkView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/09/07.
//

import SwiftUI

struct RegisterHouseworkView: View {
    
    @State var houseworkTitle = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.space16) {
            Text("家事を追加")
                .font(with: .headLineL)
            ZStack {
                TextField("家事の名前を入力", text: $houseworkTitle)
                    .foregroundStyle(.primary1)
                    .padding()
                    .font(with: .body)
                    .background {
                        RoundedRectangle(radius: .radius8)
                            .foregroundStyle(.primary3)
                    }
                Button {
                    tappedClearTextFiledButton()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.primary2)
                        .padding(DesignSystem.Space.space8)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, DesignSystem.Space.space8)
                .opacity(houseworkTitle.isEmpty ? 0 : 1)
            }
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Space.space16)
    }
}

private extension RegisterHouseworkView {
    
    func tappedClearTextFiledButton() {
        
        withAnimation {
            
            houseworkTitle = ""
        }
    }
}

#Preview {
    RegisterHouseworkView()
}
