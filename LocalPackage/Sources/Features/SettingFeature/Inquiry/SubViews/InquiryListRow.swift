//
//  InquiryListRow.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 問い合わせの一覧の1行
struct InquiryListRow: View {

    @Environment(\.locale) var locale
    @Environment(\.calendar) var calendar
    @Environment(\.timeZone) var timeZone

    let inquiry: Inquiry

    var body: some View {
        HStack(spacing: .space16) {
            VStack(alignment: .leading, spacing: .space4) {
                HStack(spacing: .space8) {
                    Text(InquiryDisplayText.category(inquiry.category))
                        .font(with: .headLineS)
                        .foregroundStyle(.textPrimary)
                    InquiryStatusLabel(status: inquiry.status)
                }
                Text(lastMessageDescription)
                    .font(with: .caption)
                    .foregroundStyle(inquiry.hasUnreadReply ? .textAccent : .textSecondary)
                Text(inquiry.lastMessageAt, format: dateFormat)
                    .font(with: .caption)
                    .foregroundStyle(.textSecondary)
            }
            Spacer()
            if inquiry.hasUnreadReply {
                Circle()
                    .fill(.fillDestructive)
                    .frame(width: 10, height: 10)
                    .accessibilityLabel(Text("未読", bundle: #bundle))
            }
            Image(systemName: "chevron.right")
                .font(with: .caption)
                .foregroundStyle(.textSecondary)
        }
        .padding(.vertical, .space8)
        .contentShape(Rectangle())
    }

}

// MARK: - UI定義

private extension InquiryListRow {

    var lastMessageDescription: LocalizedStringResource {
        if inquiry.hasUnreadReply {
            return .localized("運営から新しい返信があります")
        }

        switch inquiry.lastMessageSender {
        case .admin:
            return .localized("運営から返信がありました")

        case .user:
            return .localized("運営からの返信をお待ちください")
        }
    }

    var dateFormat: Date.FormatStyle {
        .init(date: .abbreviated, time: .shortened, locale: locale, calendar: calendar, timeZone: timeZone)
    }

}

// MARK: - Preview定義

#if DEBUG
#Preview("InquiryListRow_返信待ち", traits: .sizeThatFitsLayout) {
    InquiryListRow(inquiry: .preview())
        .padding(.horizontal, .space16)
        .environment(\.timeZone, .tokyo)
}

#Preview("InquiryListRow_未読の返信あり", traits: .sizeThatFitsLayout) {
    InquiryListRow(inquiry: .preview(
        category: .usage,
        status: .inProgress,
        lastMessageSender: .admin,
        hasUnreadReply: true,
        messageCount: 2
    ))
    .padding(.horizontal, .space16)
    .environment(\.timeZone, .tokyo)
}

#Preview("InquiryListRow_対応済み", traits: .sizeThatFitsLayout) {
    InquiryListRow(inquiry: .preview(
        category: .account,
        status: .resolved,
        lastMessageSender: .admin,
        messageCount: 3
    ))
    .padding(.horizontal, .space16)
    .environment(\.timeZone, .tokyo)
}
#endif
