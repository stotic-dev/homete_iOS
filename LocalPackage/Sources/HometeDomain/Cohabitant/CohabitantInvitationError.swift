//
//  CohabitantInvitationError.swift
//  LocalPackage
//

/// 招待リンクによるグループ参加で発生するエラー
public enum CohabitantInvitationError: Error, Equatable, Sendable {

    /// 招待が見つからない（無効なリンク）
    case notFound
    /// 招待の有効期限が切れている
    case expired
    /// すでに別のグループに参加している
    case alreadyJoined

}

public extension CohabitantInvitationError {

    /// Functionsが`details`に載せる招待固有のエラーコードのキー
    static let serverCodeKey = "invitationErrorCode"

    /// Functionsの`details`に載ったコードから招待固有のエラーを組み立てる
    ///
    /// 標準のエラーコードでは招待固有の失敗と通信起因の失敗を区別できないため、
    /// Functions側が`details`に載せたコードだけを招待エラーとして扱う。
    /// - Parameter serverCode: `details`の`invitationErrorCode`の値
    /// - Returns: 対応する招待エラー（招待固有の失敗でない場合はnil）
    init?(serverCode: String) {
        switch serverCode {
        case "invitation-not-found", "cohabitant-not-found":
            self = .notFound

        case "invitation-expired":
            self = .expired

        case "already-joined":
            self = .alreadyJoined

        default:
            // account-not-found は招待の発行時にしか起きず、参加時の分岐に対応するものがない
            return nil
        }
    }

}
