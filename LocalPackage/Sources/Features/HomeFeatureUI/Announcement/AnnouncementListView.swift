//
//  AnnouncementListView.swift
//  LocalPackage
//

import HometeModel
import HometeUI
import SwiftUI

/// お知らせの一覧画面の中身
public struct AnnouncementListView: View {

    let state: AnnouncementState
    let unreadIds: Set<String>
    let onTapAnnouncement: (Announcement) -> Void
    let onRefresh: () async -> Void
    let onTapRetry: () -> Void
    let onTapClose: () -> Void

    public init(
        state: AnnouncementState,
        unreadIds: Set<String>,
        onTapAnnouncement: @escaping (Announcement) -> Void,
        onRefresh: @escaping () async -> Void,
        onTapRetry: @escaping () -> Void,
        onTapClose: @escaping () -> Void
    ) {
        self.state = state
        self.unreadIds = unreadIds
        self.onTapAnnouncement = onTapAnnouncement
        self.onRefresh = onRefresh
        self.onTapRetry = onTapRetry
        self.onTapClose = onTapClose
    }

    public var body: some View {
        content()
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

private extension AnnouncementListView {

    @ViewBuilder
    func content() -> some View {
        if !state.announcements.isEmpty {
            announcementList()
        } else if state.hasLoaded {
            emptyContent()
        } else if !state.isRefreshing, let failure = state.loadFailure {
            // 再読み込みを押した後は、取り直している間スピナーに切り替えて押したことが分かるようにする
            LoadErrorView(error: failure, onTapRetry: onTapRetry)
        } else {
            ProgressView()
        }
    }

    func announcementList() -> some View {
        ScrollView {
            LazyVStack(spacing: .zero) {
                ForEach(Array(state.announcements.enumerated()), id: \.element.id) { index, announcement in
                    Button {
                        onTapAnnouncement(announcement)
                    } label: {
                        AnnouncementListRow(announcement: announcement, isUnread: unreadIds.contains(announcement.id))
                    }
                    .buttonStyle(.plain)
                    if index < state.announcements.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, .space16)
            .padding(.vertical, .space8)
            .background(.backgroundCard)
            .cornerRadius(.radius20)
            .padding(.space16)
        }
        .refreshable {
            await onRefresh()
        }
    }

    func emptyContent() -> some View {
        ScrollView {
            VStack(spacing: .space16) {
                HometteView(.normal)
                Text("お知らせはまだありません", bundle: #bundle)
                    .font(with: .headLineM)
                    .multilineTextAlignment(.center)
                Text("運営からのお知らせが届くと、ここに表示されます。", bundle: #bundle)
                    .font(with: .body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, .space16)
            .padding(.vertical, .space40)
        }
        .refreshable {
            await onRefresh()
        }
    }

}

// MARK: - Preview定義

#if DEBUG
#Preview("AnnouncementListView_一覧") {
    NavigationStack {
        AnnouncementListView(
            state: .init(
                announcements: [
                    .preview(id: "1", title: "新しい機能が使えるようになりました", isUnread: true),
                    .preview(id: "2", linkUrl: nil),
                    .preview(id: "3", title: "年末年始のお問い合わせへの返信について", linkUrl: nil),
                ],
                hasLoaded: true
            ),
            unreadIds: ["1"],
            onTapAnnouncement: { _ in },
            onRefresh: {},
            onTapRetry: {},
            onTapClose: {}
        )
    }
    .environment(\.timeZone, .tokyo)
}

#Preview("AnnouncementListView_空") {
    NavigationStack {
        AnnouncementListView(
            state: .init(hasLoaded: true),
            unreadIds: [],
            onTapAnnouncement: { _ in },
            onRefresh: {},
            onTapRetry: {},
            onTapClose: {}
        )
    }
}

#Preview("AnnouncementListView_取得失敗") {
    NavigationStack {
        AnnouncementListView(
            state: .init(loadFailure: .noNetwork),
            unreadIds: [],
            onTapAnnouncement: { _ in },
            onRefresh: {},
            onTapRetry: {},
            onTapClose: {}
        )
    }
}
#endif
