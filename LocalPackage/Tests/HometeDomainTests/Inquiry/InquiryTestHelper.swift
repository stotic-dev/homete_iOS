//
//  InquiryTestHelper.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain

extension Inquiry {

    static func makeForTest(
        id: String,
        status: InquiryStatus = .open,
        hasUnreadReply: Bool = false,
        updatedAt: Date = Date(timeIntervalSince1970: 0)
    ) -> Inquiry {
        .init(
            id: id,
            category: .bug,
            status: status,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: updatedAt,
            lastMessageAt: updatedAt,
            lastMessageSender: hasUnreadReply ? .admin : .user,
            hasUnreadReply: hasUnreadReply,
            messageCount: 1
        )
    }

}

extension InquiryMessage {

    static func makeForTest(id: String, sender: InquiryMessageSender = .user) -> InquiryMessage {
        .init(id: id, sender: sender, body: "本文\(id)", createdAt: Date(timeIntervalSince1970: 0))
    }

}
