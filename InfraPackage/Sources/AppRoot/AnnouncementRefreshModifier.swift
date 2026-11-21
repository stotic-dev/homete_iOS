//
//  AnnouncementRefreshModifier.swift
//

import HometeDomain
import HometeDomainUI
import SwiftUI

/// 運営からのお知らせを取り直し、ダッシュボードのバッジと起動時のシートに反映する
///
/// メイン画面を出したとき・フォアグラウンドに戻ったとき・アプリを開いている間にお知らせの通知を受け取ったときに取り直す。
struct AnnouncementRefreshModifier: ViewModifier {

    @Environment(\.scenePhase) var scenePhase

    let announcementStore: AnnouncementStore

    func body(content: Content) -> some View {
        content
            .task {
                await announcementStore.refresh()
            }
            .onChange(of: scenePhase) {
                guard scenePhase == .active else { return }
                refresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: .didReceiveAnnouncementNotification)) { _ in
                refresh()
            }
    }

}

private extension AnnouncementRefreshModifier {

    func refresh() {
        Task {
            await announcementStore.refresh()
        }
    }

}

extension View {

    func refreshAnnouncements(_ announcementStore: AnnouncementStore) -> some View {
        modifier(AnnouncementRefreshModifier(announcementStore: announcementStore))
    }

}
