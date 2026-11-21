//
//  AnnouncementDetailView.swift
//  LocalPackage
//

import HometeModel
import HometeUI
import SwiftUI

/// お知らせの詳細画面の中身
public struct AnnouncementDetailView: View {

    let announcement: Announcement
    let onTapLink: (URL) -> Void

    public init(
        announcement: Announcement,
        onTapLink: @escaping (URL) -> Void
    ) {
        self.announcement = announcement
        self.onTapLink = onTapLink
    }

    public var body: some View {
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
