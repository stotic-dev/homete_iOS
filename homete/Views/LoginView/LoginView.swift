//
//  LoginView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/03.
//

import SwiftUI

struct LoginView: View {
    var body: some View {
        VStack {
            SignInUpWithAppleButton()
                .frame(minHeight: 45)
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    LoginView()
}
