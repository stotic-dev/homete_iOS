//
//  CohabitantRegistrationProcessingView.swift
//  homete
//
//  Created by 佐藤汰一 on 2025/08/17.
//

import HometeResources
import HometeUI
import SwiftUI

/// 登録処理の完了を待つ画面
/// - Note: 役割の通知・同居人IDの共有・完了の待ち合わせは`CohabitantRegistrationStateMachine`が扱うため、
///         このViewは待っていることを伝えるだけに留める
struct CohabitantRegistrationProcessingView: View {

    var body: some View {
        VStack(spacing: .zero) {
            VStack(spacing: .space16) {
                VStack(spacing: .zero) {
                    Text("登録はもうすぐ完了します！")
                    Text("共に家事を頑張るパートナーへ、エールを送り合いませんか？")
                }
                .font(with: .headLineM)
                Image(.cohabitantsHandShake)
                    .resizable()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(.radius8)
                Text("しばらくお待ちください")
                    .font(with: .caption)
            }
            Spacer()
                .frame(height: .space24)
            Indicator()
            Spacer()
        }
        .padding(.horizontal, .space16)
    }

}

#Preview("CohabitantRegistrationProcessingView_通常ケース") {
    CohabitantRegistrationProcessingView()
    #if canImport(Prefire)
        .prefireIgnored()
    #endif
}
