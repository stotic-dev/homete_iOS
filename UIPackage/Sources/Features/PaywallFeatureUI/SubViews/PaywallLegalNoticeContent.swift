//
//  PaywallLegalNoticeContent.swift
//  LocalPackage
//

import HometeModel
import HometeUI
import SwiftUI

/// 自動更新・解約方法の説明と、利用規約・プライバシーポリシーへのリンク
///
/// App Store審査ガイドライン3.1.2で、自動更新のサブスクリプションの購入画面に出すよう求められている
public struct PaywallLegalNoticeContent: View {

    public init() {}

    public var body: some View {
        VStack(spacing: .space16) {
            Text(
                "お支払いはApple Accountに請求されます。期間が終わる24時間前までに解約しない限り、サブスクリプションは自動で更新されます。解約は、App Storeのアカウント設定からいつでも行えます。",
                bundle: #bundle
            )
            .font(with: .caption)
            .foregroundStyle(.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: .space24) {
                if let url = URL(string: Constants.termsOfServiceURLString) {
                    Link(destination: url) {
                        Text("利用規約", bundle: #bundle)
                    }
                }
                if let url = URL(string: Constants.privacyPolicyURLString) {
                    Link(destination: url) {
                        Text("プライバシーポリシー", bundle: #bundle)
                    }
                }
            }
            .font(with: .caption)
            .foregroundStyle(.textAccent)
        }
    }

}

#Preview("PaywallLegalNoticeContent", traits: .sizeThatFitsLayout) {
    PaywallLegalNoticeContent()
        .padding()
}
