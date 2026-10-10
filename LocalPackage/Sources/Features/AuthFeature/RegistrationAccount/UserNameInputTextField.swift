//
//  UserNameInputTextField.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/27.
//

import HometeDomain
import HometeResources
import HometeUI
import SwiftUI

struct UserNameInputTextField: View {

    @Binding var userName: UserName

    var body: some View {
        VStack(spacing: .space16) {
            HStack(spacing: .space8) {
                TextField(text: $userName.value) {
                    Text("例：たろう", bundle: #bundle)
                }
                .font(with: .body)
                Button {
                    userName.value = ""
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.textPrimary)
                }
            }
            .padding(.horizontal, .space16)
            .padding(.vertical, .space24)
            .background {
                RoundedRectangle(radius: .radius20)
                    .fill(.backgroundCard)
            }
            ZStack {
                if userName.isOverLimitCharacters {
                    Text("10文字以内で入力して下さい", bundle: #bundle)
                        .foregroundStyle(.textDestructive)
                } else {
                    Text("あと\(userName.remainingCharacters)文字", bundle: #bundle)
                }
            }
            .font(with: .body)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

}

#Preview("UserNameInputTextField_入力値なし", traits: .sizeThatFitsLayout) {
    UserNameInputTextField(userName: .constant(.init(value: "")))
        .padding(.space16)
        .background(.backgroundScreen)
}

#Preview("UserNameInputTextField_10文字入力", traits: .sizeThatFitsLayout) {
    UserNameInputTextField(userName: .constant(.init(value: "hogehogeho")))
        .padding(.space16)
        .background(.backgroundScreen)
}

#Preview("UserNameInputTextField_10文字以上入力", traits: .sizeThatFitsLayout) {
    UserNameInputTextField(userName: .constant(.init(value: "hogehogehog")))
        .padding(.space16)
        .background(.backgroundScreen)
}
