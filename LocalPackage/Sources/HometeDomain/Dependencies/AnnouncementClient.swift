//
//  AnnouncementClient.swift
//  LocalPackage
//

public struct AnnouncementClient: Sendable {

    /// 起動中のアプリのバージョンに配信中のお知らせを、`publishedAt`の新しい順に取得する
    /// - Note: 取得しただけでは既読にならない
    public let list: @Sendable () async throws -> AnnouncementList
    /// 表示したお知らせまでを既読にする
    /// - Note: 既読位置は戻らない。古いお知らせを渡しても変わらない
    /// - Parameters:
    ///   - announcementId: 一覧なら先頭（最新）のお知らせ、モーダルなら`modalAnnouncementId`
    ///   - scope: どこで表示したか
    public let markRead: @Sendable (_ announcementId: String, _ scope: AnnouncementReadScope) async throws -> Void

    public init(
        list: @Sendable @escaping () async throws -> AnnouncementList = {
            .init(announcements: [.preview()], unreadCount: 0, modalAnnouncementId: nil)
        },
        markRead: @Sendable @escaping (
            _ announcementId: String,
            _ scope: AnnouncementReadScope
        ) async throws -> Void = { _, _ in }
    ) {
        self.list = list
        self.markRead = markRead
    }

}

public extension AnnouncementClient {

    static let previewValue: AnnouncementClient = .init()

}
