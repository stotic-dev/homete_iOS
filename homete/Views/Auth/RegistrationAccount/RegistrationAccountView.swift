//
//  RegistrationAccountView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/20.
//

import SwiftUI

struct RegistrationAccountView: View {
    @State var inputUserName = ""
    
    var body: some View {
        AppNavigationStackView { _ in
            VStack(spacing: .zero) {
                Text("まずはあなたのニックネームを教えてください")
                    .font(with: .body)
                    .foregroundStyle(.primary2)
                TextField("例：たろう", text: $inputUserName)
                Spacer()
            }
            .padding(.horizontal, .space16)
            .navigationTitle("アカウント登録")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    RegistrationAccountView()
}
