//
//  InquiryListState.swift
//  LocalPackage
//

import Foundation

/// 問い合わせの一覧の状態
public struct InquiryListState: Equatable, Sendable {

    /// `updatedAt`の新しい順
    public var inquiries: [Inquiry] = []
    /// 未読の返信がある問い合わせの総数（取得していない次のページの分も含む）
    public var unreadCount = 0
    /// 次のページを取るときに渡す値。`nil`なら最後のページまで取得済み
    public var nextCursor: String?
    /// 一度でも取得に成功したか。取得前の空と、問い合わせが1件も無い空を見分ける
    public var hasLoaded = false
    public var isRefreshing = false
    public var isLoadingMore = false
    /// 直近の取り直しに失敗した理由
    public var loadFailure: DomainError?

    public init(
        inquiries: [Inquiry] = [],
        unreadCount: Int = 0,
        nextCursor: String? = nil,
        hasLoaded: Bool = false,
        isRefreshing: Bool = false,
        isLoadingMore: Bool = false,
        loadFailure: DomainError? = nil
    ) {
        self.inquiries = inquiries
        self.unreadCount = unreadCount
        self.nextCursor = nextCursor
        self.hasLoaded = hasLoaded
        self.isRefreshing = isRefreshing
        self.isLoadingMore = isLoadingMore
        self.loadFailure = loadFailure
    }

    public var hasMore: Bool {
        nextCursor != nil
    }

}
