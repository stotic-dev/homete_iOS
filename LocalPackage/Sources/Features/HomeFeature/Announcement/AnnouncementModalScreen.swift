//
//  AnnouncementModalScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// 起動時に出すお知らせのシート
/// - Note: 既読にするのは、閉じたことを受け取る出す側（`HomeView`）で行う。下へのスワイプで閉じたときも既読にするため
struct AnnouncementModalScreen: View {

    @Environment(\.openURL) var openURL
    @Environment(\.dismiss) var dismiss

    let announcement: Announcement

    var body: some View {
        NavigationStack {
            AnnouncementModalView(
                announcement: announcement,
                onTapLink: { url in openURL(url) },
                onTapClose: { dismiss() }
            )
        }
        .trackScreenView(.announcementModal)
    }

}

/// 起動時に出すお知らせのシートの中身
struct AnnouncementModalView: View {

    let announcement: Announcement
    let onTapLink: (URL) -> Void
    let onTapClose: () -> Void

    var body: some View {
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
