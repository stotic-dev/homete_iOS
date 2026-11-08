//
//  AnnouncementList.swift
//  LocalPackage
//

/// 配信中のお知らせと、未読・起動時に出すお知らせ
public struct AnnouncementList: Equatable, Sendable {

    /// `publishedAt`の新しい順（最大50件。起動時に出すお知らせが古いときは末尾に足される）
    public let announcements: [Announcement]
    /// 未読のお知らせの数
    public let unreadCount: Int
    /// 起動時にモーダルで出すお知らせのID。`announcements`に必ず含まれる。出すものが無ければ`nil`
    public let modalAnnouncementId: String?

    public init(announcements: [Announcement], unreadCount: Int, modalAnnouncementId: String?) {
        self.announcements = announcements
        self.unreadCount = unreadCount
        self.modalAnnouncementId = modalAnnouncementId
    }

}

/// どこで表示したお知らせを既読にするか
public enum AnnouncementReadScope: String, Equatable, Sendable {

    /// 一覧を開いた。未読とモーダルの両方の既読位置が進む
    case list
    /// モーダルを閉じた。モーダルの既読位置だけが進み、一覧の未読は残る
    case modal

}
