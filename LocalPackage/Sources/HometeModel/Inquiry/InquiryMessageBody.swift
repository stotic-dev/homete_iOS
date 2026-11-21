//
//  InquiryMessageBody.swift
//  LocalPackage
//

/// 問い合わせのメッセージの本文が送れる内容かどうかの判定
public enum InquiryMessageBody: Equatable, Sendable {

    /// 送れる
    case valid
    /// 空、または空白・改行だけ
    case empty
    /// 上限の文字数を超えている
    case tooLong

    /// 本文の上限の文字数
    /// - Note: サーバーは書記素クラスタで数えるため、Swiftの`String.count`とそろう
    public static let maxLength = 2000

    /// 結合文字を重ねた巨大な1文字への備えとして、サーバーがあわせて見ているUTF-16の上限
    static let maxUTF16Length = 32000

    public init(_ text: String) {
        if text.allSatisfy(\.isWhitespace) {
            self = .empty
        } else if text.count > Self.maxLength || text.utf16.count > Self.maxUTF16Length {
            self = .tooLong
        } else {
            self = .valid
        }
    }

}
