//
//  RegistrationAccountView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/12/20.
//

import HometeModel
import HometeResources
import HometeUI
import SwiftUI

/// 呼び名を登録する画面
/// - Note: アカウントの登録は`RegistrationAccountScreen`が受け持つ
public struct RegistrationAccountView: View {

    @State var inputUserName = UserName()
    /// 入力した呼び名で「次へ」を押した
    let onTapNext: (UserName) -> Void

    public init(onTapNext: @escaping (UserName) -> Void) {
        self.onTapNext = onTapNext
    }

    public var body: some View {
        VStack(spacing: .space24) {
            VStack(spacing: .space16) {
                // 入力中はキーボードで画面が狭くなるため、小さく出す
                HometteView(.wave, size: .small)
                Text("なんと呼べばいいですか？", bundle: #bundle)
                    .font(with: .headLineM)
                    .multilineTextAlignment(.center)
                Text("ニックネームでも大丈夫です。パートナーの画面にも表示され、あとから変えられます", bundle: #bundle)
                    .font(with: .body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            UserNameInputTextField(userName: $inputUserName)
            Spacer(minLength: .space24)
            Button {
                onTapNext(inputUserName)
            } label: {
                Text("次へ", bundle: #bundle)
                    .padding(.vertical, .space8)
                    .frame(maxWidth: .infinity)
            }
            .primaryButtonStyle()
            .disabled(!inputUserName.canRegistration)
            Spacer()
                .frame(height: .space24)
        }
        // ほかのオンボーディングの画面と同じく、ナビゲーションバーを出さずに見出しで問いかける
        .padding(.horizontal, .space16)
        .padding(.top, .space48)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.backgroundScreen)
    }

}

#Preview("RegistrationAccountView_未入力") {
    RegistrationAccountView(onTapNext: { _ in })
}

#Preview("RegistrationAccountView_入力済み") {
    RegistrationAccountView(onTapNext: { _ in })
}
