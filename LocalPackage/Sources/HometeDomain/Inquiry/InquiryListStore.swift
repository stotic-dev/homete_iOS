//
//  InquiryListStore.swift
//  LocalPackage
//

import Observation

/// 問い合わせの一覧と、未読の返信がある問い合わせの件数を扱うStore
///
/// 設定画面の導線のバッジと一覧画面で同じ状態を使うため、設定画面を開いている間だけ1つ持つ。
@MainActor
@Observable
public final class InquiryListStore {

    public private(set) var state = InquiryListState()

    // MARK: Dependencies

    private let inquiryClient: InquiryClient

    public init(inquiryClient: InquiryClient = .previewValue) {
        self.inquiryClient = inquiryClient
    }

    /// 先頭のページから取り直す
    /// - Note: 取得中にもう一度呼ばれた場合は何もしない。失敗しても取得済みの一覧は残す
    public func refresh() async {
        guard !state.isRefreshing else { return }

        state.isRefreshing = true
        defer { state.isRefreshing = false }

        do {
            let page = try await inquiryClient.list(nil)
            state.inquiries = page.inquiries
            state.nextCursor = page.nextCursor
            state.unreadCount = page.unreadCount
            state.loadFailure = nil
            state.hasLoaded = true
        } catch {
            // 画面を閉じて取得がキャンセルされた場合は失敗として扱わない
            guard !Task.isCancelled else { return }
            state.loadFailure = DomainError.make(error) ?? .other
        }
    }

    /// 次のページを取得して末尾に足す
    /// - Note: 失敗しても、次に末尾まで表示したときにもう一度取りにいく
    public func loadMore() async {
        guard let cursor = state.nextCursor, !state.isLoadingMore, !state.isRefreshing else { return }

        state.isLoadingMore = true
        defer { state.isLoadingMore = false }

        do {
            let page = try await inquiryClient.list(cursor)
            // ページをめくる間に更新された問い合わせは前のページへ移っていることがあるため、IDで重複を除く
            let loadedIds = Set(state.inquiries.map(\.id))
            state.inquiries += page.inquiries.filter { !loadedIds.contains($0.id) }
            state.nextCursor = page.nextCursor
            state.unreadCount = page.unreadCount
        } catch {
            return
        }
    }

    /// 詳細画面での送信・既読を一覧へ反映する
    ///
    /// 一覧を取り直さずに、戻ったときの並びと未読の件数をそろえる。
    /// - Parameter inquiry: 送信・既読を反映した後の問い合わせ
    public func apply(_ inquiry: Inquiry) {
        let previous = state.inquiries.first { $0.id == inquiry.id }
        if previous?.hasUnreadReply == true, !inquiry.hasUnreadReply {
            state.unreadCount = max(state.unreadCount - 1, 0)
        } else if previous?.hasUnreadReply == false, inquiry.hasUnreadReply {
            state.unreadCount += 1
        }

        state.inquiries.removeAll { $0.id == inquiry.id }
        // 一覧はupdatedAtの新しい順に並べる
        let insertIndex = state.inquiries.firstIndex { $0.updatedAt < inquiry.updatedAt } ?? state.inquiries.endIndex
        state.inquiries.insert(inquiry, at: insertIndex)
    }

}
