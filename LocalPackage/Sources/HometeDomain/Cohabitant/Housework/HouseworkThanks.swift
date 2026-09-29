//
//  HouseworkThanks.swift
//  homete
//

import Foundation

/// 完了した家事に届いた「ありがとう」
public struct HouseworkThanks: Equatable, Sendable, Hashable, Codable {

    /// ありがとうを送ったユーザID
    public let senderId: String
    /// 添えられたメッセージ
    public let comment: String
    /// 送った日時
    public let sentAt: Date

    public init(senderId: String, comment: String, sentAt: Date) {
        self.senderId = senderId
        self.comment = comment
        self.sentAt = sentAt
    }

}
