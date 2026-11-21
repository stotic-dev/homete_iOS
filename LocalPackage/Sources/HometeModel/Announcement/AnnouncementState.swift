//
//  AnnouncementState.swift
//  LocalPackage
//

import Foundation

/// 運営からのお知らせの状態
public struct AnnouncementState: Equatable, Sendable {

    /// `publishedAt`の新しい順
    public var announcements: [Announcement] = []
    /// 未読のお知らせの数。ベルのバッジに使う
    public var unreadCount = 0
    /// 起動時にモーダルで出すお知らせ。起動後に初めて取得できたときに決まる。出すものが無ければ`nil`
    public var modalAnnouncement: Announcement?
    /// 一度でも取得に成功したか。取得前の空と、お知らせが1件も無い空を見分ける
    public var hasLoaded = false
    public var isRefreshing = false
    /// 直近の取り直しに失敗した理由
    public var loadFailure: DomainError?

    public init(
        announcements: [Announcement] = [],
        unreadCount: Int = 0,
        modalAnnouncement: Announcement? = nil,
        hasLoaded: Bool = false,
        isRefreshing: Bool = false,
        loadFailure: DomainError? = nil
    ) {
        self.announcements = announcements
        self.unreadCount = unreadCount
        self.modalAnnouncement = modalAnnouncement
        self.hasLoaded = hasLoaded
        self.isRefreshing = isRefreshing
        self.loadFailure = loadFailure
    }

}
