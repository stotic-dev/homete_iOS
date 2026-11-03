//
//  Announcement+Preview.swift
//  LocalPackage
//

import Foundation

public extension Announcement {

    /// Previewと既定のClientで使うお知らせ
    static func preview(
        id: String = "preview-announcement",
        title: String = "メンテナンスのお知らせ",
        body: String = "11月10日（月）2:00〜4:00に、サーバーのメンテナンスを行います。メンテナンス中はアプリを使えません。ご不便をおかけしますが、よろしくお願いします。",
        linkUrl: URL? = URL(string: "https://example.com/announcement"),
        isUnread: Bool = false,
        // VRTで日付表示がブレないよう固定値にする（2026/10/24 12:00 JST）。
        // 既定のClientからも使うため、DEBUG限定の`Date.previewDate`は使わない
        publishedAt: Date = Date(timeIntervalSince1970: 1_792_810_800)
    ) -> Announcement {
        .init(
            id: id,
            title: title,
            body: body,
            linkUrl: linkUrl,
            publishedAt: publishedAt,
            updatedAt: publishedAt,
            isUnread: isUnread
        )
    }

}
