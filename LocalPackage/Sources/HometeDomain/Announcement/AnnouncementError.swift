//
//  AnnouncementError.swift
//  LocalPackage
//

/// お知らせのAPIが返す、お知らせ固有のエラー
public enum AnnouncementError: Error, Equatable, Sendable {

    /// 形式の違反
    case invalidArgument
    /// お知らせが見つからない（公開前・取り下げ済み・呼び出したユーザーに見えないものも同じ扱い）
    case notFound

}

public extension AnnouncementError {

    /// Functionsが`details`に載せるお知らせ固有のエラーコードのキー
    static let serverCodeKey = "announcementErrorCode"

    /// Functionsの`details`に載ったコードからお知らせ固有のエラーを組み立てる
    ///
    /// 標準のエラーコードでは、関数が未デプロイのときの`not-found`と区別できないため、
    /// Functions側が`details`に載せたコードだけをお知らせのエラーとして扱う。
    /// - Parameter serverCode: `details`の`announcementErrorCode`の値
    /// - Returns: 対応するエラー（お知らせ固有の失敗でない場合はnil）
    init?(serverCode: String) {
        switch serverCode {
        case "invalid-argument":
            self = .invalidArgument

        case "announcement-not-found":
            self = .notFound

        default:
            return nil
        }
    }

}
