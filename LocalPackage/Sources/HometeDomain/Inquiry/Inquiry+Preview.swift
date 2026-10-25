//
//  Inquiry+Preview.swift
//  LocalPackage
//

import Foundation

public extension Inquiry {

    /// Previewと既定のClientで使う問い合わせ
    static func preview(
        id: String = "preview-inquiry",
        category: InquiryCategory = .bug,
        status: InquiryStatus = .open,
        lastMessageSender: InquiryMessageSender = .user,
        hasUnreadReply: Bool = false,
        messageCount: Int = 1,
        // VRTで日付表示がブレないよう固定値にする（2026/10/24 12:00 JST）。
        // 既定のClientからも使うため、DEBUG限定の`Date.previewDate`は使わない
        updatedAt: Date = Date(timeIntervalSince1970: 1_792_810_800)
    ) -> Inquiry {
        .init(
            id: id,
            category: category,
            status: status,
            createdAt: updatedAt,
            updatedAt: updatedAt,
            lastMessageAt: updatedAt,
            lastMessageSender: lastMessageSender,
            hasUnreadReply: hasUnreadReply,
            messageCount: messageCount
        )
    }

}

public extension InquiryMessage {

    /// Previewと既定のClientで使う、ユーザーが送ったメッセージ
    static let previewUser = InquiryMessage(
        id: "preview-user-message",
        sender: .user,
        body: "家事を完了にしても、ボードに反映されないことがあります。",
        createdAt: Date(timeIntervalSince1970: 1_792_810_800)
    )

    /// Previewで使う、運営からの返信
    static let previewAdmin = InquiryMessage(
        id: "preview-admin-message",
        sender: .admin,
        body: "お問い合わせありがとうございます。お使いの端末で、アプリを再起動したあとも同じ状態になるか教えていただけますか。",
        createdAt: Date(timeIntervalSince1970: 1_792_821_600)
    )

}
