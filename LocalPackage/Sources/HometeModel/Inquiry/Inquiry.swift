//
//  Inquiry.swift
//  LocalPackage
//

import Foundation

/// アプリ内の問い合わせ
///
/// 本文はメッセージとして持つ（最初のメッセージが問い合わせの本文）。件名は持たない。
public struct Inquiry: Identifiable, Equatable, Sendable {

    public let id: String
    public let category: InquiryCategory
    public let status: InquiryStatus
    public let createdAt: Date
    /// 一覧の並び順に使う。メッセージの追加・対応状況の変更で更新される（既読では変わらない）
    public let updatedAt: Date
    public let lastMessageAt: Date
    public let lastMessageSender: InquiryMessageSender
    /// 運営からの返信を未読のまま残しているか
    public let hasUnreadReply: Bool
    public let messageCount: Int

    public init(
        id: String,
        category: InquiryCategory,
        status: InquiryStatus,
        createdAt: Date,
        updatedAt: Date,
        lastMessageAt: Date,
        lastMessageSender: InquiryMessageSender,
        hasUnreadReply: Bool,
        messageCount: Int
    ) {
        self.id = id
        self.category = category
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastMessageAt = lastMessageAt
        self.lastMessageSender = lastMessageSender
        self.hasUnreadReply = hasUnreadReply
        self.messageCount = messageCount
    }

}

/// 問い合わせの種別
/// - Note: `rawValue`はAPIに送る値
public enum InquiryCategory: String, CaseIterable, Equatable, Sendable {

    /// 不具合
    case bug
    /// 要望
    case feature
    /// 使い方
    case usage
    /// アカウント・課金
    case account
    case other

}

/// 問い合わせの対応状況
/// - Note: `rawValue`はAPIが返す値
public enum InquiryStatus: String, Equatable, Sendable {

    /// 未対応
    case open
    /// 対応中
    case inProgress
    /// 対応済み。ユーザーが追加で送ると`open`に戻る
    case resolved

}

/// 問い合わせのメッセージの送り手
public enum InquiryMessageSender: String, Equatable, Sendable {

    case user
    /// 運営
    case admin

}

/// 問い合わせのメッセージ
public struct InquiryMessage: Identifiable, Equatable, Sendable {

    public let id: String
    public let sender: InquiryMessageSender
    /// プレーンテキストとして表示する
    public let body: String
    public let createdAt: Date

    public init(id: String, sender: InquiryMessageSender, body: String, createdAt: Date) {
        self.id = id
        self.sender = sender
        self.body = body
        self.createdAt = createdAt
    }

}
