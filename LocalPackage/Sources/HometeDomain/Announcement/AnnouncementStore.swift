//
//  AnnouncementStore.swift
//  LocalPackage
//

import Foundation
import Observation

/// 運営からのお知らせの一覧・未読の数・起動時に出すお知らせを扱うStore
///
/// ダッシュボードのベルのバッジ・起動時のモーダル・一覧で同じ状態を使うため、メイン画面（`AppTabView`）が1つ持つ。
@MainActor
@Observable
public final class AnnouncementStore {

    public private(set) var state = AnnouncementState()

    /// 進行中の取得。取得中にもう一度呼ばれたら、新しく取りにいかずにこれを待つ
    private var refreshTask: Task<Void, Never>?
    /// この端末で既読にした一覧の位置
    ///
    /// 既読にする前に始めた取得が後から返ってきても、未読の数が戻らないようにするために使う。
    private var listReadUntil: Date?
    /// 起動時に出すお知らせを決めたか
    ///
    /// 起動時のモーダルは、起動後に初めて取得できたときの1回だけ決める。復帰時や通知の受信で取り直すたびに決め直すと、
    /// ダッシュボードの上で別の画面を開いている最中にシートを出そうとしてしまうため。
    private var hasDecidedModalAnnouncement = false

    // MARK: Dependencies

    private let announcementClient: AnnouncementClient

    public init(announcementClient: AnnouncementClient = .previewValue) {
        self.announcementClient = announcementClient
    }

    /// 取り直す
    /// - Note: 取得中にもう一度呼ばれた場合は、進行中の取得が終わるのを待つ。失敗しても取得済みの内容は残す。
    ///         ベルと一覧で同じ取得を使い回すため、呼び出した画面が閉じても取得は止めない
    public func refresh() async {
        if let refreshTask {
            await refreshTask.value
            return
        }

        // 取得を終えたらすぐに片付ける。呼び出し元が戻るのを待ってから片付けると、その間に呼ばれた取り直しが
        // 終わった取得を待つだけで、取りにいかずに終わってしまう
        let task = Task {
            await self.fetch()
            self.refreshTask = nil
        }
        refreshTask = task
        await task.value
    }

    /// お知らせがまだ読まれていないか
    ///
    /// 各お知らせの`isUnread`は取り直すまで変わらないため、この端末で既読にした位置より前のものは既読として扱う。
    public func isUnread(_ announcement: Announcement) -> Bool {
        guard announcement.isUnread else { return false }
        guard let listReadUntil else { return true }
        return announcement.publishedAt > listReadUntil
    }

    /// 一覧を開いたときに、先頭（最新）のお知らせまでを既読にする
    ///
    /// 未読の数とモーダルはすぐに消す。各お知らせの`isUnread`は次に取り直すまでそのままにする。
    /// - Note: 一覧を開いている間にお知らせが変わるたびに呼ばれるため、既読にした位置より新しいお知らせが無ければ何もしない。
    ///         失敗しても画面には出さない。既読にした位置を戻し、次の取得で未読が戻るようにする
    public func markListRead() async {
        guard let latest = state.announcements.first else { return }
        if let listReadUntil, latest.publishedAt <= listReadUntil {
            return
        }

        let previousListReadUntil = listReadUntil
        listReadUntil = latest.publishedAt
        state.unreadCount = 0
        state.modalAnnouncement = nil

        do {
            try await announcementClient.markRead(latest.id, .list)
        } catch {
            // 待っている間に、より新しいお知らせで既読にし直していたら戻さない
            if listReadUntil == latest.publishedAt {
                listReadUntil = previousListReadUntil
            }
        }
    }

    /// 起動時のモーダルを閉じたときに、そのお知らせを既読にする
    ///
    /// 出している間に一覧を開くなどして今の状態が変わっていることがあるため、表示したお知らせを既読にする。
    /// - Note: 一覧の未読は残る。失敗しても画面には出さない（次の起動で同じお知らせがまた出る）
    /// - Parameter announcement: モーダルで表示したお知らせ
    public func markModalRead(_ announcement: Announcement) async {
        state.modalAnnouncement = nil

        try? await announcementClient.markRead(announcement.id, .modal)
    }

}

private extension AnnouncementStore {

    func fetch() async {
        state.isRefreshing = true
        defer { state.isRefreshing = false }

        do {
            let list = try await announcementClient.list()
            state.announcements = list.announcements
            state.unreadCount = unreadCount(in: list)
            if !hasDecidedModalAnnouncement {
                hasDecidedModalAnnouncement = true
                state.modalAnnouncement = modalAnnouncement(in: list)
            }
            state.loadFailure = nil
            state.hasLoaded = true
        } catch {
            state.loadFailure = DomainError.make(error) ?? .other
        }
    }

    func unreadCount(in list: AnnouncementList) -> Int {
        guard let listReadUntil else { return list.unreadCount }

        // 既読にした位置より後に公開されたものだけが未読として残りうる
        let unreadAfterRead = list.announcements.count { $0.publishedAt > listReadUntil }
        return min(list.unreadCount, unreadAfterRead)
    }

    func modalAnnouncement(in list: AnnouncementList) -> Announcement? {
        guard let modalId = list.modalAnnouncementId else { return nil }
        return list.announcements.first { $0.id == modalId }
    }

}

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
