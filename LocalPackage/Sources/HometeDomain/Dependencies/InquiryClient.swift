//
//  InquiryClient.swift
//  LocalPackage
//

public struct InquiryClient: Sendable {

    /// 問い合わせを作る。最初のメッセージが本文になる
    /// - Note: アプリ・OSのバージョンと端末の機種も一緒に送る
    public let create: @Sendable (_ request: InquiryCreationRequest) async throws -> InquiryPostResult
    /// 自分の問い合わせを`updatedAt`の新しい順に取得する
    /// - Parameter cursor: 前のページの`nextCursor`。最初のページは`nil`
    public let list: @Sendable (_ cursor: String?) async throws -> InquiryListPage
    /// 問い合わせの詳細と、メッセージ履歴を新しい順に取得する
    /// - Note: 取得しただけでは既読にならない
    /// - Parameter cursor: 前のページの`nextCursor`。最新のメッセージから取るときは`nil`
    public let fetch: @Sendable (_ inquiryId: String, _ cursor: String?) async throws -> InquiryDetailPage
    /// 問い合わせにメッセージを追加で送る
    /// - Parameter requestId: 送信ごとに作り、送り直すときは同じ値を使う
    public let sendMessage: @Sendable (
        _ inquiryId: String,
        _ requestId: String,
        _ body: String
    ) async throws -> InquiryPostResult
    /// 表示したメッセージまでを既読にする
    /// - Parameter messageId: 画面に表示した最新のメッセージ
    /// - Returns: 既読を反映した後の問い合わせ
    public let markRead: @Sendable (_ inquiryId: String, _ messageId: String) async throws -> Inquiry

    public init(
        create: @Sendable @escaping (_ request: InquiryCreationRequest) async throws -> InquiryPostResult = { _ in
            .init(inquiry: .preview(), message: .previewUser)
        },
        list: @Sendable @escaping (_ cursor: String?) async throws -> InquiryListPage = { _ in
            .init(inquiries: [], nextCursor: nil, unreadCount: 0)
        },
        fetch: @Sendable @escaping (
            _ inquiryId: String,
            _ cursor: String?
        ) async throws -> InquiryDetailPage = { _, _ in
            .init(inquiry: .preview(), messages: [], nextCursor: nil)
        },
        sendMessage: @Sendable @escaping (
            _ inquiryId: String,
            _ requestId: String,
            _ body: String
        ) async throws -> InquiryPostResult = { _, _, _ in
            .init(inquiry: .preview(), message: .previewUser)
        },
        markRead: @Sendable @escaping (_ inquiryId: String, _ messageId: String) async throws -> Inquiry = { _, _ in
            .preview()
        }
    ) {
        self.create = create
        self.list = list
        self.fetch = fetch
        self.sendMessage = sendMessage
        self.markRead = markRead
    }

}

public extension InquiryClient {

    static let previewValue: InquiryClient = .init()

}
