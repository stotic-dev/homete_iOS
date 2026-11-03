//
//  Announcement.swift
//  LocalPackage
//

import Foundation

/// 運営が配信するお知らせ
public struct Announcement: Equatable, Sendable, Hashable, Identifiable {

    public let id: String
    public let title: String
    /// プレーンテキスト。HTML・Markdownとして表示しない
    public let body: String
    /// 本文の続きなどを案内するページ。httpsのURLだけを持つ
    public let linkUrl: URL?
    /// 一覧の並び順と既読の判定に使う。公開後は変わらない
    public let publishedAt: Date
    /// 公開後に編集されると変わる（既読には影響しない）
    public let updatedAt: Date
    public let isUnread: Bool

    public init(
        id: String,
        title: String,
        body: String,
        linkUrl: URL?,
        publishedAt: Date,
        updatedAt: Date,
        isUnread: Bool
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.linkUrl = linkUrl
        self.publishedAt = publishedAt
        self.updatedAt = updatedAt
        self.isUnread = isUnread
    }

}
