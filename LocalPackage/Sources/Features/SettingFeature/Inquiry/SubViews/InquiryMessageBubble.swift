//
//  InquiryMessageBubble.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 問い合わせのメッセージ1件の吹き出し
///
/// 自分が送ったものは右、運営からの返信は左に寄せる。
struct InquiryMessageBubble: View {

    @Environment(\.locale) var locale
    @Environment(\.calendar) var calendar
    @Environment(\.timeZone) var timeZone

    let message: InquiryMessage

    var body: some View {
        VStack(alignment: isOwn ? .trailing : .leading, spacing: .space4) {
            if !isOwn {
                Text("運営", bundle: #bundle, comment: "問い合わせの返信の送り手として出す、アプリの運営者")
                    .font(with: .boldCaption)
                    .foregroundStyle(.textSecondary)
            }
            // 本文はプレーンテキストとして出す。Markdownとして解釈させない
            Text(verbatim: message.body)
                .font(with: .body)
                .foregroundStyle(.textPrimary)
                .textSelection(.enabled)
                .padding(.horizontal, .space16)
                .padding(.vertical, .space8)
                .background(isOwn ? .fillAccentSubtle : .backgroundCard, in: RoundedRectangle(radius: .radius20))
            Text(message.createdAt, format: dateFormat)
                .font(with: .caption)
                .foregroundStyle(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: isOwn ? .trailing : .leading)
        .padding(isOwn ? .leading : .trailing, .space40)
    }

}

// MARK: - UI定義

private extension InquiryMessageBubble {

    var isOwn: Bool {
        message.sender == .user
    }

    var dateFormat: Date.FormatStyle {
        .init(date: .abbreviated, time: .shortened, locale: locale, calendar: calendar, timeZone: timeZone)
    }

}

// MARK: - Preview定義

#Preview("InquiryMessageBubble_自分", traits: .sizeThatFitsLayout) {
    InquiryMessageBubble(message: .previewUser)
        .padding(.space16)
        .background(.backgroundScreen)
        .environment(\.timeZone, TimeZone(identifier: "Asia/Tokyo") ?? .current)
}

#Preview("InquiryMessageBubble_運営", traits: .sizeThatFitsLayout) {
    InquiryMessageBubble(message: .previewAdmin)
        .padding(.space16)
        .background(.backgroundScreen)
        .environment(\.timeZone, TimeZone(identifier: "Asia/Tokyo") ?? .current)
}
