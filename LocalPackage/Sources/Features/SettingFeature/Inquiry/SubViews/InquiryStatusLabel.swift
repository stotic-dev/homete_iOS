//
//  InquiryStatusLabel.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 問い合わせの対応状況を表す小さなラベル
struct InquiryStatusLabel: View {

    let status: InquiryStatus

    var body: some View {
        Text(InquiryDisplayText.status(status))
            .font(with: .boldCaption)
            .foregroundStyle(foregroundStyle)
            .padding(.horizontal, .space8)
            .padding(.vertical, .space4)
            .background(backgroundStyle, in: Capsule())
    }

}

// MARK: - UI定義

private extension InquiryStatusLabel {

    var foregroundStyle: Color {
        switch status {
        case .open, .inProgress:
            .textPrimary

        case .resolved:
            .textSecondary
        }
    }

    var backgroundStyle: Color {
        switch status {
        case .open:
            .fillAccentSubtle

        case .inProgress:
            .fillRewardSubtle

        case .resolved:
            .backgroundScreen
        }
    }

}

// MARK: - Preview定義

#Preview("InquiryStatusLabel", traits: .sizeThatFitsLayout) {
    HStack(spacing: .space8) {
        InquiryStatusLabel(status: .open)
        InquiryStatusLabel(status: .inProgress)
        InquiryStatusLabel(status: .resolved)
    }
    .padding(.space16)
    .background(.backgroundCard)
}
