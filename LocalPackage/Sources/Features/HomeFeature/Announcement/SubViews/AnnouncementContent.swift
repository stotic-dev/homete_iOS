//
//  AnnouncementContent.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// お知らせのタイトル・公開日・本文
///
/// 詳細画面と起動時のシートで同じ見せ方にするため、ここにまとめる。
struct AnnouncementContent: View {

    let announcement: Announcement

    var body: some View {
        VStack(alignment: .leading, spacing: .space16) {
            VStack(alignment: .leading, spacing: .space4) {
                Text(announcement.title)
                    .font(with: .headLineM)
                    .foregroundStyle(.textPrimary)
                AnnouncementPublishedDateText(date: announcement.publishedAt)
            }
            // 運営が書いた本文はプレーンテキストとして出す。Markdownとして解釈させないよう`verbatim`にする
            Text(verbatim: announcement.body)
                .font(with: .body)
                .foregroundStyle(.textPrimary)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

// MARK: - Preview定義

#if DEBUG
#Preview("AnnouncementContent", traits: .sizeThatFitsLayout) {
    AnnouncementContent(announcement: .preview())
        .padding(.space16)
        .environment(\.timeZone, .tokyo)
}
#endif
