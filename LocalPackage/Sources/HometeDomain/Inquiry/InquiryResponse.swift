//
//  InquiryResponse.swift
//  LocalPackage
//

/// 問い合わせの一覧の1ページ
public struct InquiryListPage: Equatable, Sendable {

    /// `updatedAt`の新しい順
    public let inquiries: [Inquiry]
    /// 次のページを取るときに渡す値。`nil`なら最後のページ
    public let nextCursor: String?
    /// ページに関わらない、未読の返信がある問い合わせの総数
    public let unreadCount: Int

    public init(inquiries: [Inquiry], nextCursor: String?, unreadCount: Int) {
        self.inquiries = inquiries
        self.nextCursor = nextCursor
        self.unreadCount = unreadCount
    }

}

/// 問い合わせの詳細と、メッセージ履歴の1ページ
public struct InquiryDetailPage: Equatable, Sendable {

    public let inquiry: Inquiry
    /// 新しい順
    public let messages: [InquiryMessage]
    /// さらに古いメッセージを取るときに渡す値。`nil`なら最も古いメッセージまで取れている
    public let nextCursor: String?

    public init(inquiry: Inquiry, messages: [InquiryMessage], nextCursor: String?) {
        self.inquiry = inquiry
        self.messages = messages
        self.nextCursor = nextCursor
    }

}

/// 問い合わせの作成・メッセージの送信の結果
public struct InquiryPostResult: Equatable, Sendable {

    /// 送信を反映した後の問い合わせ
    public let inquiry: Inquiry
    /// 送ったメッセージ
    public let message: InquiryMessage

    public init(inquiry: Inquiry, message: InquiryMessage) {
        self.inquiry = inquiry
        self.message = message
    }

}

/// 問い合わせを作るときに送る内容
/// - Note: アプリ・OSのバージョンと端末の機種は、Clientの実装が付け足して送る
public struct InquiryCreationRequest: Equatable, Sendable {

    /// 送信ごとに作り、通信に失敗して送り直すときは同じ値を使う。同じ値ならサーバーは新たに登録しない
    public let requestId: String
    public let category: InquiryCategory
    public let body: String

    public init(requestId: String, category: InquiryCategory, body: String) {
        self.requestId = requestId
        self.category = category
        self.body = body
    }

}
