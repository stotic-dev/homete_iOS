//
//  HouseworkThanks.swift
//  homete
//

import Foundation

/// 完了した家事に届いた「ありがとう」の記録
///
/// 家事ドキュメントの`thanks`に、送った人のユーザIDをキーにして持つ（[ADR-0025](doc/adr/0025-store-housework-thanks-in-housework-document.md)）。
public struct HouseworkThanks: Equatable, Sendable, Hashable, Codable {

    /// コメントの最大文字数
    public static let commentMaxLength = 200

    /// 添えたコメント。完了リストのハート・クイックアクション・一括操作から送った場合は`nil`
    public let comment: String?
    /// 最初に送った日時（コメントを編集しても変えない）
    public let sentAt: Date

    public init(comment: String?, sentAt: Date) {
        self.comment = comment
        self.sentAt = sentAt
    }

}
