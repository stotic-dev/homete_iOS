//
//  AnnouncementTestHelper.swift
//  LocalPackage
//

import Foundation
@testable import HometeDomain

extension Announcement {

    /// - Parameter publishedAt: 1970年からの秒数。並び順と既読の位置を決める
    static func makeForTest(id: String, publishedAt: TimeInterval, isUnread: Bool = false) -> Announcement {
        .init(
            id: id,
            title: "タイトル\(id)",
            body: "本文\(id)",
            linkUrl: nil,
            publishedAt: Date(timeIntervalSince1970: publishedAt),
            updatedAt: Date(timeIntervalSince1970: publishedAt),
            isUnread: isUnread
        )
    }

}
