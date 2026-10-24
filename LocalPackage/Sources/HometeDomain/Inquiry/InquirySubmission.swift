//
//  InquirySubmission.swift
//  LocalPackage
//

/// 問い合わせの作成・メッセージの送信で、入力中の本文と送信の状態を持つ
///
/// 通信に失敗して送り直したときに重複して登録されないよう、送り直しでは同じ`requestId`を使う。
/// `requestId`は送信に成功するまで持ち続け、本文を書き直しても変えない
/// （最初の送信がサーバーに届いていた場合は、サーバーが最初の内容を返す）。
public struct InquirySubmission: Equatable, Sendable {

    public var body: String
    /// 送信中か。送信中は次の送信を受け付けない
    public private(set) var isSending: Bool
    /// 直近の送信に失敗した理由
    public var failure: InquiryFailure?
    /// 送信に成功していない送信の`requestId`
    public private(set) var requestId: String?

    public init(
        body: String = "",
        isSending: Bool = false,
        failure: InquiryFailure? = nil,
        requestId: String? = nil
    ) {
        self.body = body
        self.isSending = isSending
        self.failure = failure
        self.requestId = requestId
    }

    public var bodyValidation: InquiryMessageBody {
        .init(body)
    }

    /// 送信ボタンを押せるか
    public var canSubmit: Bool {
        !isSending && bodyValidation == .valid
    }

    /// 送信を始める
    /// - Parameter makeRequestId: まだ`requestId`が無いときに作る
    /// - Returns: 送信に使う`requestId`。送信中・本文が送れない内容のときは`nil`
    mutating func begin(makeRequestId: () -> String) -> String? {
        guard canSubmit else { return nil }

        let requestId = requestId ?? makeRequestId()
        self.requestId = requestId
        isSending = true
        failure = nil
        return requestId
    }

    /// 送信に成功したら、入力を空にして次の送信で新しい`requestId`を作るようにする
    mutating func succeed() {
        body = ""
        requestId = nil
        isSending = false
    }

    /// 送信に失敗したら、入力と`requestId`を残して送り直せるようにする
    mutating func fail(_ error: any Error) {
        isSending = false
        failure = .init(error)
    }

}
