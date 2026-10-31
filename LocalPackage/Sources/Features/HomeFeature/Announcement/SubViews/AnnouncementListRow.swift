//
//  AnnouncementListRow.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// お知らせの一覧の1行
struct AnnouncementListRow: View {

    let announcement: Announcement
    let isUnread: Bool

    var body: some View {
        HStack(spacing: .space16) {
            VStack(alignment: .leading, spacing: .space4) {
                Text(announcement.title)
                    .font(with: .headLineS)
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.leading)
                AnnouncementPublishedDateText(date: announcement.publishedAt)
            }
            // タイトルが長いときに、行の幅いっぱいまで使ってから折り返す
            .frame(maxWidth: .infinity, alignment: .leading)
            if isUnread {
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

// MARK: - Preview定義

#if DEBUG
#Preview("AnnouncementListRow_既読", traits: .sizeThatFitsLayout) {
    AnnouncementListRow(announcement: .preview(), isUnread: false)
        .padding(.horizontal, .space16)
        .environment(\.timeZone, .tokyo)
}

#Preview("AnnouncementListRow_未読_長いタイトル", traits: .sizeThatFitsLayout) {
    AnnouncementListRow(
        announcement: .preview(title: "年末年始のお問い合わせへの返信と、メンテナンスの予定について"),
        isUnread: true
    )
    .padding(.horizontal, .space16)
    .environment(\.timeZone, .tokyo)
}
#endif
