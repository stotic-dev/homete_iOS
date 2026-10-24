//
//  InquiryBodyLengthLabel.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 問い合わせの本文の文字数と上限
///
/// 上限を超えたら、何文字以内にすればよいかを添えて目立たせる。
struct InquiryBodyLengthLabel: View {

    let length: Int
    let isTooLong: Bool

    var body: some View {
        HStack(spacing: .space8) {
            if isTooLong {
                Text("\(InquiryMessageBody.maxLength)文字以内で入力してください", bundle: #bundle)
            }
            Spacer()
            Text("\(length) / \(InquiryMessageBody.maxLength)", bundle: #bundle)
                .monospacedDigit()
        }
        .font(with: .caption)
        .foregroundStyle(isTooLong ? .textDestructive : .textSecondary)
    }

}

// MARK: - Preview定義

#Preview("InquiryBodyLengthLabel_上限以内", traits: .sizeThatFitsLayout) {
    InquiryBodyLengthLabel(length: 120, isTooLong: false)
        .padding(.space16)
}

#Preview("InquiryBodyLengthLabel_上限超過", traits: .sizeThatFitsLayout) {
    InquiryBodyLengthLabel(length: 2001, isTooLong: true)
        .padding(.space16)
}
