//
//  AnnouncementListScreen.swift
//  LocalPackage
//

import HometeDomain
import HometeUI
import SwiftUI

/// お知らせの一覧画面（ダッシュボードのベルから開くシート）
///
/// ベルのバッジと同じ`AnnouncementStore`を使い、開いたら先頭のお知らせまでを既読にする。
struct AnnouncementListScreen: View {

    @Environment(AnnouncementStore.self) var announcementStore
    @Environment(\.dismiss) var dismiss

    @State var navigationPath = AppNavigationPath<AnnouncementRoute>()
    /// 未読のドットを出すお知らせ
    ///
    /// 開いた瞬間に既読にするため、`isUnread`をそのまま使うと取り直したときにドットが消え、どれが新しいか分からなくなる。
    /// 開いている間に見えた未読を覚えておき、閉じるまでドットを出し続ける。
    @State var unreadIds: Set<String> = []

    var body: some View {
        NavigationStack(path: $navigationPath.path) {
            AnnouncementListView(
                state: announcementStore.state,
                unreadIds: unreadIds,
                onTapAnnouncement: { announcement in navigationPath.push(.detail(announcement)) },
                onRefresh: { await announcementStore.refresh() },
                onTapRetry: { refresh() },
                onTapClose: { dismiss() }
            )
            .navigationDestination(for: AnnouncementRoute.self) { route in
                navigationHandler(route)
            }
        }
        // NavigationStackの外から渡し、pushした画面にも届ける
        .environment(\.announcementNavigationPath, navigationPath)
        .task {
            await announcementStore.refresh()
        }
        // 取得済みの内容でもすぐに既読にし、開いている間に新しいお知らせが届いたらそれも既読にする
        .onChange(of: announcementStore.state.announcements, initial: true) { _, announcements in
            changedAnnouncements(announcements)
        }
        .trackScreenView(.announcementList)
    }

}

// MARK: - プレゼンテーションロジック

private extension AnnouncementListScreen {

    @ViewBuilder
    func navigationHandler(_ route: AnnouncementRoute) -> some View {
        switch route {
        case let .detail(announcement):
            AnnouncementDetailScreen(announcement: announcement)
        }
    }

    func refresh() {
        Task {
            await announcementStore.refresh()
        }
    }

    func changedAnnouncements(_ announcements: [Announcement]) {
        // 既読にすると判定が変わるため、既読にする前に見ておく
        unreadIds.formUnion(announcements.filter(announcementStore.isUnread).map(\.id))
        Task {
            await announcementStore.markListRead()
        }
    }

}

/// お知らせの一覧画面の中身
struct AnnouncementListView: View {

    let state: AnnouncementState
    let unreadIds: Set<String>
    let onTapAnnouncement: (Announcement) -> Void
    let onRefresh: () async -> Void
    let onTapRetry: () -> Void
    let onTapClose: () -> Void

    var body: some View {
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
        } else if let failure = state.loadFailure {
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
