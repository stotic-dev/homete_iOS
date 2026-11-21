//
//  AnnouncementListScreen.swift
//  LocalPackage
//

import HometeDomainUI
import HomeFeatureUI
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
    /// 開いている間に見えた未読を覚えておき、詳細を開くか一覧を閉じるまでドットを出し続ける。
    @State var unreadIds: Set<String> = []

    var body: some View {
        NavigationStack(path: $navigationPath.path) {
            AnnouncementListView(
                state: announcementStore.state,
                unreadIds: unreadIds,
                onTapAnnouncement: { announcement in tappedAnnouncement(announcement) },
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

    func tappedAnnouncement(_ announcement: Announcement) {
        // 詳細で読んだので、一覧に戻ったときにはドットを出さない
        unreadIds.remove(announcement.id)
        navigationPath.push(.detail(announcement))
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
