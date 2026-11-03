//
//  AnnouncementDetailScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// お知らせの詳細画面（一覧から開く）
struct AnnouncementDetailScreen: View {

    @Environment(\.openURL) var openURL

    let announcement: Announcement

    var body: some View {
        AnnouncementDetailView(announcement: announcement) { url in
            openURL(url)
        }
        .trackScreenView(.announcementDetail)
    }

}

/// お知らせの詳細画面の中身
struct AnnouncementDetailView: View {

    let announcement: Announcement
    let onTapLink: (URL) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: .space24) {
                AnnouncementContent(announcement: announcement)
                if let linkUrl = announcement.linkUrl {
                    Button {
                        onTapLink(linkUrl)
                    } label: {
                        Text("詳しく見る", bundle: #bundle)
                            .padding(.vertical, .space8)
                            .frame(maxWidth: .infinity)
                    }
                    .primaryButtonStyle()
                }
            }
            .padding(.space16)
            .background(.backgroundCard)
            .cornerRadius(.radius20)
            .padding(.space16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundScreen)
        .navigationTitle(.localized("お知らせ"))
        .inlineNavigationBarTitleDisplayMode()
    }

}

// MARK: - Preview定義

#if DEBUG
#Preview("AnnouncementDetailView_リンクあり") {
    NavigationStack {
        AnnouncementDetailView(announcement: .preview()) { _ in }
    }
    .environment(\.timeZone, .tokyo)
}

#Preview("AnnouncementDetailView_リンクなし") {
    NavigationStack {
        AnnouncementDetailView(announcement: .preview(linkUrl: nil)) { _ in }
    }
    .environment(\.timeZone, .tokyo)
}
#endif
