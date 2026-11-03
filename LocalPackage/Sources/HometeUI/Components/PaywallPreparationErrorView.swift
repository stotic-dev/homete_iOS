//
//  PaywallPreparationErrorView.swift
//  LocalPackage
//

import HometeModel
import SwiftUI

/// 購入の準備（購入者をアカウントに結び付けること）に失敗したとき、Paywallの代わりに出す画面
///
/// 準備ができないまま購入すると、加入がアカウントに反映されないため、Paywallを出さずにやり直してもらう。
/// - Note: 課金の画面なので、ほめっとは出さない（`ux-writing.md`）
public struct PaywallPreparationErrorView: View {

    let onTapRetry: () -> Void
    let onTapClose: () -> Void

    public init(onTapRetry: @escaping () -> Void, onTapClose: @escaping () -> Void) {
        self.onTapRetry = onTapRetry
        self.onTapClose = onTapClose
    }

    public var body: some View {
        // 大きな文字で画面に収まらなくても読み切れるよう、丸ごとスクロールさせる
        ScrollView {
            VStack(spacing: .space24) {
                VStack(spacing: .space16) {
                    Image(systemName: "exclamationmark.icloud")
                        .font(.system(size: 56))
                        .foregroundStyle(.iconDecorative)
                        .accessibilityHidden(true)
                    Text("プレミアムプランの準備ができませんでした", bundle: #bundle)
                        .font(with: .headLineM)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("通信状態をご確認のうえ、もう一度お試しください。", bundle: #bundle)
                        .font(with: .body)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                VStack(spacing: .space16) {
                    Button {
                        onTapRetry()
                    } label: {
                        Text("もう一度試す", bundle: #bundle)
                            .padding(.vertical, .space8)
                            .frame(maxWidth: .infinity)
                    }
                    .primaryButtonStyle()
                    Button {
                        onTapClose()
                    } label: {
                        Text("閉じる", bundle: #bundle)
                            .padding(.vertical, .space8)
                            .frame(maxWidth: .infinity)
                    }
                    .subPrimaryButtonStyle()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, .space16)
            .padding(.top, .space48)
            .padding(.bottom, .space24)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

}

#Preview {
    PaywallPreparationErrorView(onTapRetry: {}, onTapClose: {})
}
