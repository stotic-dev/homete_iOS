//
//  InquiryDetailState.swift
//  LocalPackage
//

import Foundation

/// 問い合わせの詳細の状態
public struct InquiryDetailState: Equatable, Sendable {

    /// 取得するまでは`nil`
    public var inquiry: Inquiry?
    /// 古い順
    public var messages: [InquiryMessage] = []
    /// さらに古いメッセージを取るときに渡す値。`nil`なら最も古いメッセージまで表示している
    public var olderCursor: String?
    public var isLoading = false
    public var isLoadingOlder = false
    /// 直近の取り直しに失敗した理由
    public var loadFailure: InquiryFailure?

    public init(
        inquiry: Inquiry? = nil,
        messages: [InquiryMessage] = [],
        olderCursor: String? = nil,
        isLoading: Bool = false,
        isLoadingOlder: Bool = false,
        loadFailure: InquiryFailure? = nil
    ) {
        self.inquiry = inquiry
        self.messages = messages
        self.olderCursor = olderCursor
        self.isLoading = isLoading
        self.isLoadingOlder = isLoadingOlder
        self.loadFailure = loadFailure
    }

    public var hasOlderMessages: Bool {
        olderCursor != nil
    }

}
