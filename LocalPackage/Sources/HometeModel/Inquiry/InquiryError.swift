//
//  InquiryError.swift
//  LocalPackage
//

/// 問い合わせのAPIが返す、問い合わせ固有のエラー
public enum InquiryError: Error, Equatable, Sendable {

    /// 形式・上限の違反
    case invalidArgument
    /// 問い合わせ・メッセージが見つからない（他人の問い合わせも同じ扱い）
    case notFound
    /// 送信頻度の上限を超えた
    case rateLimited

}

public extension InquiryError {

    /// Functionsが`details`に載せる問い合わせ固有のエラーコードのキー
    static let serverCodeKey = "inquiryErrorCode"

    /// アカウントの削除が始まった後に作成・送信したときにFunctionsが返すコード
    /// - Note: 問い合わせそのものの失敗ではないため`InquiryError`のケースにはせず、
    ///         Client側で認証エラーへ読み替える
    static let accountDeletedServerCode = "account-deleted"

    /// Functionsの`details`に載ったコードから問い合わせ固有のエラーを組み立てる
    ///
    /// 標準のエラーコードでは、関数が未デプロイのときの`not-found`と区別できないため、
    /// Functions側が`details`に載せたコードだけを問い合わせのエラーとして扱う。
    /// - Parameter serverCode: `details`の`inquiryErrorCode`の値
    /// - Returns: 対応するエラー（問い合わせ固有の失敗でない場合はnil）
    init?(serverCode: String) {
        switch serverCode {
        case "invalid-argument":
            self = .invalidArgument

        case "inquiry-not-found", "message-not-found":
            self = .notFound

        case "rate-limited":
            self = .rateLimited

        default:
            return nil
        }
    }

}

/// 問い合わせの取得・送信に失敗した理由
public enum InquiryFailure: Equatable, Sendable {

    /// 送信頻度の上限を超えた
    case rateLimited
    /// 入力内容がサーバーの上限に合わない
    case invalidInput
    /// 問い合わせが見つからない
    case notFound
    /// 通信エラーなど、問い合わせに固有でない失敗
    case domain(DomainError)

    public init(_ error: any Error) {
        switch error {
        case InquiryError.rateLimited:
            self = .rateLimited

        case InquiryError.invalidArgument:
            self = .invalidInput

        case InquiryError.notFound:
            self = .notFound

        default:
            self = .domain(DomainError.make(error) ?? .other)
        }
    }

}
