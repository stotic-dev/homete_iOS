//
//  AnnouncementModalView.swift
//  LocalPackage
//

import HometeModel
import HometeUI
import SwiftUI

/// 起動時に出すお知らせのシートの中身
public struct AnnouncementModalView: View {

    let announcement: Announcement
    let onTapLink: (URL) -> Void
    let onTapClose: () -> Void

    public init(
        announcement: Announcement,
        onTapLink: @escaping (URL) -> Void,
        onTapClose: @escaping () -> Void
    ) {
        self.announcement = announcement
        self.onTapLink = onTapLink
        self.onTapClose = onTapClose
    }

    public var body: some View {
        ScrollView {
            AnnouncementContent(announcement: announcement)
                .padding(.space16)
        }
        .safeAreaInset(edge: .bottom) {
            buttons()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundScreen)
        .navigationTitle(.localized("お知らせ"))
        .inlineNavigationBarTitleDisplayMode()
        .leadingToolbarItem {
            NavigationBarButton(label: .close) {
                onTapClose()
            }
        }
    }

}

// MARK: - UI定義

private extension AnnouncementModalView {

    func buttons() -> some View {
        VStack(spacing: .space8) {
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
            Button {
                onTapClose()
            } label: {
                Text("閉じる", bundle: #bundle)
                    .padding(.vertical, .space8)
                    .frame(maxWidth: .infinity)
            }
            .subPrimaryButtonStyle()
        }
        .padding(.space16)
        .background(.backgroundScreen)
    }

}

// MARK: - Preview定義

#if DEBUG
#Preview("AnnouncementModalView_リンクあり") {
    NavigationStack {
        AnnouncementModalView(announcement: .preview(), onTapLink: { _ in }, onTapClose: {})
    }
    .environment(\.timeZone, .tokyo)
}

#Preview("AnnouncementModalView_リンクなし_長い本文") {
    NavigationStack {
        AnnouncementModalView(
            announcement: .preview(
                body: String(repeating: "いつもhometeを使っていただき、ありがとうございます。", count: 30),
                linkUrl: nil
            ),
            onTapLink: { _ in },
            onTapClose: {}
        )
    }
    .environment(\.timeZone, .tokyo)
}
#endif
